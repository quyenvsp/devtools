// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app/src/screens/network/network_request_inspector.dart';
import 'package:devtools_test/devtools_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vm_service/vm_service.dart';

import '../test_infra/test_data/network.dart';
import '../test_infra/utils/test_utils.dart';

void main() {
  group('NetworkRequestInspector', () {
    late NetworkController controller;
    late FakeServiceManager fakeServiceManager;
    final HttpProfileRequest? httpRequest =
        HttpProfileRequest.parse(httpPostJson);
    String clipboardContents = '';

    setUp(() {
      setGlobal(IdeTheme, IdeTheme());
      setGlobal(DevToolsExtensionPoints, ExternalDevToolsExtensionPoints());
      setGlobal(PreferencesController, PreferencesController());
      clipboardContents = '';
      fakeServiceManager = FakeServiceManager(
        service: FakeServiceManager.createFakeService(
          httpProfile: HttpProfile(
            requests: [
              httpRequest!,
            ],
            timestamp: 0,
          ),
        ),
      );
      setGlobal(ServiceConnectionManager, fakeServiceManager);
      setGlobal(NotificationService, NotificationService());
      controller = NetworkController();
      setupClipboardCopyListener(
        clipboardContentsCallback: (contents) {
          clipboardContents = contents ?? '';
        },
      );
    });

    testWidgets('copy request body', (tester) async {
      final requestsNotifier = controller.requests;

      await controller.startRecording();

      await tester.pumpWidget(
        wrapWithControllers(
          NetworkRequestInspector(controller),
          debugger: createMockDebuggerControllerWithDefaults(),
        ),
      );

      // Load the network request.
      await controller.networkService.refreshNetworkData();
      expect(requestsNotifier.value.requests.length, equals(1));

      // Select the request in the network request list.
      final networkRequest = requestsNotifier.value.requests.first;
      controller.selectedRequest.value = networkRequest;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Request'));
      await tester.pumpAndSettle();

      // Tap the requestBody copy button.
      expect(clipboardContents, isEmpty);
      await tester.tap(find.byType(CopyToClipboardControl));
      final expectedResponseBody =
          jsonDecode(utf8.decode(httpRequest!.requestBody!.toList()));

      // Check that the contents were copied to clipboard.
      expect(clipboardContents, isNotEmpty);
      expect(
        jsonDecode(clipboardContents),
        equals(expectedResponseBody),
      );

      controller.stopRecording();

      // pumpAndSettle so residual http timers can clear.
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('copy response body', (tester) async {
      final requestsNotifier = controller.requests;

      await controller.startRecording();

      await tester.pumpWidget(
        wrapWithControllers(
          NetworkRequestInspector(controller),
          debugger: createMockDebuggerControllerWithDefaults(),
        ),
      );

      // Load the network request.
      await controller.networkService.refreshNetworkData();
      expect(requestsNotifier.value.requests.length, equals(1));

      // Select the request in the network request list.
      final networkRequest = requestsNotifier.value.requests.first;
      controller.selectedRequest.value = networkRequest;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Response'));
      await tester.pumpAndSettle();

      // Tap the responseBody copy button.
      expect(clipboardContents, isEmpty);
      await tester.tap(find.byType(CopyToClipboardControl));
      final expectedResponseBody =
          jsonDecode(utf8.decode(httpRequest!.responseBody!.toList()));

      // Check that the contents were copied to clipboard.
      expect(clipboardContents, isNotEmpty);
      expect(
        jsonDecode(clipboardContents),
        equals(expectedResponseBody),
      );

      controller.stopRecording();

      // pumpAndSettle so residual http timers can clear.
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });
  });
}
