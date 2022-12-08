
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart';

class GeospatialAnchorWidget extends StatefulWidget {
  GeospatialAnchorWidget({Key? key}) : super(key: key);
  @override
  _GeospatialAnchorWidgetState createState() => _GeospatialAnchorWidgetState();
}

class _GeospatialAnchorWidgetState extends State<GeospatialAnchorWidget> {


  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  @override
  void dispose() {
    super.dispose();
    arSessionManager!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cloud Anchors'),
        ),
        body: Container(
            child: Stack(children: [
              ARView(
                onARViewCreated: onARViewCreated,
                planeDetectionConfig: PlaneDetectionConfig.horizontal,
              ),
              Align(
                alignment: FractionalOffset.bottomCenter,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: onRemoveEverything,
                          child: Text("Remove Everything")),
                    ]),
              ),
              Align(
                alignment: FractionalOffset.topCenter,
                child: ElevatedButton(
                              onPressed: onUploadButtonPressed,
                              child: Text("Place"),
                ),
              ),
            ])));
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: true,
      showAnimatedGuide: false,
      handleTaps: false,
    );

    arLocationManager.startLocationUpdates();

    this.arObjectManager!.onInitialize();
    this.arAnchorManager!.initGeospatialMode("***");

    this.arObjectManager!.onNodeTap = onNodeTapped;
  }

  Future<void> onRemoveEverything() async {
    anchors.forEach((anchor) {
      this.arAnchorManager!.removeAnchor(anchor);
    });
    anchors = [];
  }

  Future<void> onNodeTapped(List<String> nodeNames) async {
    var foregroundNode =
    nodes.firstWhere((element) => element.name == nodeNames.first);
    this.arSessionManager!.onError(foregroundNode.data!["onTapText"]);
  }

  Future<void> onUploadButtonPressed() async {
    var newAnchor = ARTerrainAnchor(name: "pizza", latitude: 59.833881, longitude: 30.400007, altitude: 0);
    bool? didAddAnchor = await this.arAnchorManager!.addAnchor(newAnchor);
    if (didAddAnchor ?? false) {
      this.anchors.add(newAnchor);
      // Add note to anchor
      var newNode = ARNode(
          type: NodeType.webGLB,
          uri: "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb",
          scale: Vector3(0.2, 0.2, 0.2),
          position: Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(1.0, 0.0, 0.0, 0.0),
          data: {"onTapText": "Ouch, that hurt!"});
      bool? didAddNodeToAnchor =
      await this.arObjectManager!.addNode(newNode);
      if (didAddNodeToAnchor ?? false) {
        this.nodes.add(newNode);
      } else {
        this.arSessionManager!.onError("Adding Node to Anchor failed");
      }
    } else {
      this.arSessionManager!.onError("Adding Anchor failed");
    }
  }
}
