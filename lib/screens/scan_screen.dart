import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanScreen extends StatefulWidget {
  final Function(bool success, String? eventId, String? message)?
  onScanAndAttendanceCompleted;

  ScanScreen({Key? key, this.onScanAndAttendanceCompleted}) : super(key: key);

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessingScan = false;
  String? _scannedEventId;

  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;
  bool _hasAttemptedPermissionRequestViaDialog = false;

  User? _currentUser;
  bool _isTorchOn = false;
  CameraFacing _currentActualCameraFacing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndHandleCameraPermission();
    });
  }

  Future<void> _checkAndHandleCameraPermission() async {
    if (!mounted) return;
    final currentStatus = await Permission.camera.status;
    if (mounted) setState(() => _cameraPermissionStatus = currentStatus);

    if (currentStatus.isDenied || currentStatus.isRestricted) {
      if (!_hasAttemptedPermissionRequestViaDialog || currentStatus.isDenied) {
        _showPermissionExplanationDialog();
      }
    } else if (currentStatus.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog();
    }
  }

  Future<void> _requestPermissionFromSystem() async {
    if (!mounted) return;
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _cameraPermissionStatus = status;
        _hasAttemptedPermissionRequestViaDialog = true;
      });
      if (!status.isGranted) {
        widget.onScanAndAttendanceCompleted?.call(
          false,
          null,
          "Người dùng từ chối quyền camera từ hệ thống.",
        );
      }
    }
  }

  void _showPermissionExplanationDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Yêu cầu quyền Camera'),
          content: Text(
            'Ứng dụng cần quyền truy cập camera để quét mã QR điểm danh. Bạn có đồng ý cấp quyền không?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Từ chối'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  setState(
                    () => _cameraPermissionStatus = PermissionStatus.denied,
                  );
                  widget.onScanAndAttendanceCompleted?.call(
                    false,
                    null,
                    "Người dùng từ chối cấp quyền camera.",
                  );
                }
              },
            ),
            TextButton(
              child: Text('Đồng ý'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _requestPermissionFromSystem();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermanentlyDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Quyền Camera bị từ chối'),
          content: Text(
            'Bạn đã từ chối vĩnh viễn quyền truy cập camera. Vui lòng vào cài đặt ứng dụng để cấp quyền thủ công nếu muốn sử dụng tính năng này.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Đóng'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onScanAndAttendanceCompleted?.call(
                  false,
                  null,
                  "Quyền camera bị từ chối vĩnh viễn.",
                );
              },
            ),
            TextButton(
              child: Text('Mở Cài đặt'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleUserCancel() {
    if (mounted && !_isProcessingScan) {
      print("ScanScreen: User cancelled scan or navigated back.");
      widget.onScanAndAttendanceCompleted?.call(
        false,
        null,
        "Người dùng hủy thao tác quét.",
      );
    }
  }

  Future<void> _processQrCodeAndRecordAttendance(String qrCodeValue) async {
    if (!mounted || _currentUser == null) {
      _showErrorSnackBar(
        "Lỗi: Không có người dùng hoặc màn hình không tồn tại.",
      );
      widget.onScanAndAttendanceCompleted?.call(
        false,
        null,
        "Lỗi: Không có người dùng hoặc màn hình không tồn tại.",
      );
      return;
    }

    setState(() {
      _isProcessingScan = true;
      _scannedEventId = qrCodeValue;
    });

    try {
      print("Processing QR code: $qrCodeValue");
      // Phân tích URL từ QR code (định dạng: /check-in?activityId=xxx&token=yyy)
      final uri = Uri.parse(qrCodeValue);
      final activityId = uri.queryParameters['activityId'];
      final token = uri.queryParameters['token'];

      if (activityId == null || token == null) {
        throw Exception("Định dạng mã QR không hợp lệ.");
      }

      print("Extracted activityId: $activityId, token: $token");
      // Lấy thông tin hoạt động từ Firestore
      final activitySnapshot =
          await FirebaseFirestore.instance
              .collection('activities')
              .doc(activityId)
              .get();
      if (!activitySnapshot.exists) {
        throw Exception("Hoạt động không tồn tại.");
      }

      final activityData = activitySnapshot.data()!;
      final qrToken = activityData['qrToken'] as String?;
      final qrTokenExpires =
          (activityData['qrTokenExpires'] as Timestamp?)?.toDate();

      if (qrToken == null || qrTokenExpires == null) {
        throw Exception("Thông tin mã QR không đầy đủ.");
      }

      print("Fetched qrToken: $qrToken, expires: $qrTokenExpires");
      // Kiểm tra tính hợp lệ của token
      if (qrToken != token) {
        throw Exception("Mã QR không hợp lệ hoặc đã bị thay đổi.");
      }

      // Kiểm tra thời gian hết hạn (dựa vào qrTokenExpires)
      final now = DateTime.now(); // 11:45 AM +07, 07/06/2025
      print("Current time: $now, Expires: $qrTokenExpires");
      if (now.isAfter(qrTokenExpires)) {
        _showSnackBar("Mã đã hết hạn.");
        widget.onScanAndAttendanceCompleted?.call(
          false,
          activityId,
          "Mã đã hết hạn.",
        );
        return;
      }

      // Lấy thông tin sự kiện để lấy eventName
      final eventName =
          activityData['title'] as String? ?? "Sự kiện (ID: $activityId)";

      // Ghi điểm danh
      await FirebaseFirestore.instance.collection('attendance_records').add({
        'userId': _currentUser!.uid,
        'userEmail': _currentUser!.email,
        'eventId': activityId,
        'eventName': eventName,
        'attendanceTime': Timestamp.now(),
        'status': 'Đã điểm danh',
      });

      _showSnackBar('Điểm danh thành công cho "$eventName"!');
      widget.onScanAndAttendanceCompleted?.call(
        true,
        activityId,
        'Điểm danh thành công cho "$eventName"!',
      );
    } catch (e) {
      print("Error during attendance processing: $e");
      _showErrorSnackBar('Lỗi khi điểm danh. Vui lòng thử lại.');
      widget.onScanAndAttendanceCompleted?.call(
        false,
        _scannedEventId,
        'Lỗi khi điểm danh. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingScan = false;
          _scannedEventId = null;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: Duration(seconds: 2)),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isProcessingScan) return false;
        _handleUserCancel();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Quét Mã Điểm Danh'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              _handleUserCancel();
            },
          ),
          actions: [
            if (_cameraPermissionStatus.isGranted && !_isProcessingScan) ...[
              IconButton(
                icon: Icon(
                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: _isTorchOn ? Colors.yellow : Colors.grey,
                ),
                iconSize: 28.0,
                onPressed: () async {
                  try {
                    await cameraController.toggleTorch();
                    if (mounted) setState(() => _isTorchOn = !_isTorchOn);
                  } catch (e) {
                    print("Lỗi bật/tắt đèn: $e");
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  _currentActualCameraFacing == CameraFacing.front
                      ? Icons.camera_front
                      : Icons.camera_rear,
                  color: Colors.white,
                ),
                iconSize: 28.0,
                onPressed: () async {
                  try {
                    await cameraController.switchCamera();
                    if (mounted)
                      setState(
                        () =>
                            _currentActualCameraFacing =
                                (_currentActualCameraFacing ==
                                        CameraFacing.back)
                                    ? CameraFacing.front
                                    : CameraFacing.back,
                      );
                  } catch (e) {
                    print("Lỗi chuyển camera: $e");
                  }
                },
              ),
            ],
          ],
        ),
        body: Builder(
          builder: (context) {
            if (!_hasAttemptedPermissionRequestViaDialog &&
                (_cameraPermissionStatus.isDenied ||
                    _cameraPermissionStatus.isRestricted) &&
                !_cameraPermissionStatus.isPermanentlyDenied) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              );
            }
            if (!_cameraPermissionStatus.isGranted) {
              String permissionMessage =
                  "Không có quyền truy cập camera để quét mã.";
              if (_cameraPermissionStatus.isPermanentlyDenied)
                permissionMessage =
                    "Quyền camera bị từ chối vĩnh viễn. Vui lòng vào cài đặt ứng dụng để cấp quyền.";
              else if (_hasAttemptedPermissionRequestViaDialog &&
                  _cameraPermissionStatus.isDenied)
                permissionMessage =
                    "Bạn đã từ chối quyền camera. Không thể quét mã.";

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.no_photography,
                        size: 70,
                        color: Colors.redAccent,
                      ),
                      SizedBox(height: 20),
                      Text(
                        permissionMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:
                            _cameraPermissionStatus.isPermanentlyDenied
                                ? openAppSettings
                                : _checkAndHandleCameraPermission,
                        child: Text(
                          _cameraPermissionStatus.isPermanentlyDenied
                              ? 'Mở Cài đặt'
                              : 'Thử lại cấp quyền',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                if (!_isProcessingScan)
                  MobileScanner(
                    controller: cameraController,
                    onDetect: (capture) {
                      if (_isProcessingScan) return;
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty &&
                          barcodes.first.rawValue != null) {
                        final String code = barcodes.first.rawValue!;
                        _processQrCodeAndRecordAttendance(code);
                      }
                    },
                    errorBuilder: (context, error, child) {
                      String errorMessage = 'Đã xảy ra lỗi với camera.';
                      if (error is MobileScannerException) {
                        final String? detailMessage =
                            error.errorDetails?.message;
                        final String displayMessage =
                            detailMessage ?? "Không có chi tiết lỗi.";
                        print(
                          "MobileScannerException: Code: ${error.errorCode.name}, DetailMessage: $displayMessage, Raw ErrorDetails: ${error.errorDetails}",
                        );
                        switch (error.errorCode) {
                          case MobileScannerErrorCode.unsupported:
                            errorMessage =
                                'Camera không được hỗ trợ hoặc không tìm thấy trên thiết bị này.';
                            break;
                          default:
                            errorMessage =
                                'Lỗi camera (${error.errorCode.name}): $displayMessage';
                            break;
                        }
                      } else {
                        print(
                          "Non-MobileScannerException: ${error.toString()}",
                        );
                        errorMessage =
                            'Lỗi không xác định: ${error.toString()}';
                      }
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 60,
                              ),
                              SizedBox(height: 16),
                              Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed:
                                    () => setState(() {
                                      _isProcessingScan = false;
                                      _scannedEventId = null;
                                    }),
                                child: Text('Thử lại Quét'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          "Đang xử lý điểm danh cho mã:\n$_scannedEventId",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (!_isProcessingScan)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green.shade300,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
