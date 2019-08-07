import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/animated_focus_light.dart';
import 'package:tutorial_coach_mark/content_target.dart';
import 'package:tutorial_coach_mark/target_focus.dart';
import 'package:tutorial_coach_mark/target_position.dart';
import 'package:tutorial_coach_mark/util.dart';

class TutorialCoachMarkWidget extends StatefulWidget {
  final List<TargetFocus> targets;
  final Function(TargetFocus) clickTarget;
  final Function() finish;
  final Color colorShadow;
  final double opacityShadow;
  final double paddingFocus;
  final Function() clickSkip;
  final AlignmentGeometry alignSkip;
  final String textSkip;
  final bool scrollTo;
  const TutorialCoachMarkWidget({
    Key key,
    this.targets,
    this.finish,
    this.paddingFocus = 10,
    this.clickTarget,
    this.alignSkip = Alignment.bottomRight,
    this.textSkip = "SKIP",
    this.clickSkip,
    this.colorShadow = Colors.black,
    this.opacityShadow = 0.8,
    this.scrollTo = false,
  }) : super(key: key);

  @override
  _TutorialCoachMarkWidgetState createState() => _TutorialCoachMarkWidgetState();
}

class _TutorialCoachMarkWidgetState extends State<TutorialCoachMarkWidget> {
  StreamController _controllerFade = StreamController<double>.broadcast();
  StreamController _controllerTapChild = StreamController<void>.broadcast();

  TargetFocus currentTarget;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          AnimatedFocusLight(
            targets: widget.targets,
            finish: widget.finish,
            paddingFocus: widget.paddingFocus,
            colorShadow: widget.colorShadow,
            opacityShadow: widget.opacityShadow,
            scrollTo: widget.scrollTo,
            clickTarget: (target) {
              if (widget.clickTarget != null) widget.clickTarget(target);
            },
            focus: (target) {
              currentTarget = target;
              _controllerFade.sink.add(1.0);
            },
            removeFocus: () {
              _controllerFade.sink.add(0.0);
            },
            streamTap: _controllerTapChild.stream,
          ),
          _buildContents(),
          _buildSkip()
        ],
      ),
    );
  }

  _buildContents() {
    return StreamBuilder(
      stream: _controllerFade.stream,
      initialData: 0.0,
      builder: (_, snapshot) {
        try {
          return AnimatedOpacity(
            opacity: snapshot.data,
            duration: Duration(milliseconds: 300),
            child: _buildPositionedsContents(),
          );
        } catch (err) {
          return Container();
        }
      },
    );
  }

  _buildPositionedsContents() {
    if (currentTarget == null) {
      return Container();
    }

    List<Widget> widgtes = List();

    TargetPosition target = getTargetCurrent(currentTarget);
    var maxDim = max(target.size.height, target.size.width);
    var targetCenter =
        Offset(target.offset.dx + target.size.width / 2, target.offset.dy + target.size.height / 2);

    double width = 0.0;

    double top;
    double bottom;
    double left;

    widgtes = currentTarget.contents.map<Widget>((i) {
      switch (i.align) {
        case AlignContent.bottom:
          {
            var sizeCircle =
                currentTarget.shape == ShapeLightFocus.RRect ? target.size.height : maxDim;
            sizeCircle = sizeCircle * 0.6 + widget.paddingFocus;
            width = MediaQuery.of(context).size.width;
            left = 0;
            top = targetCenter.dy + sizeCircle;
            bottom = null;
          }
          break;
        case AlignContent.top:
          {
            var sizeCircle =
                currentTarget.shape == ShapeLightFocus.RRect ? target.size.height : maxDim;
            sizeCircle = sizeCircle * 0.6 + widget.paddingFocus;
            width = MediaQuery.of(context).size.width;
            left = 0;
            top = null;
            bottom = sizeCircle + (MediaQuery.of(context).size.height - targetCenter.dy);
          }
          break;
        case AlignContent.left:
          {
            var sizeCircle =
                currentTarget.shape == ShapeLightFocus.RRect ? target.size.width : maxDim;
            sizeCircle = sizeCircle * 0.6 + widget.paddingFocus;
            width = targetCenter.dx - sizeCircle;
            left = 0;
            top = targetCenter.dy - target.size.height / 2 - sizeCircle;
            bottom = null;
          }
          break;
        case AlignContent.right:
          {
            var sizeCircle = target.size.height * 0.6 + widget.paddingFocus;
            left = targetCenter.dx + sizeCircle;
            width = MediaQuery.of(context).size.width - left;
            top = targetCenter.dy - target.size.height / 2 - sizeCircle;
            bottom = null;
          }
          break;
      }

      Scrollable.ensureVisible(currentTarget.keyTarget.currentContext);

      return Positioned(
        top: top,
        bottom: bottom,
        left: left,
        child: GestureDetector(
          onTap: () {
            _controllerTapChild.add(null);
          },
          child: Container(
            width: width,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: i.child,
            ),
          ),
        ),
      );
    }).toList();

    return Stack(
      children: widgtes,
    );
  }

  _buildSkip() {
    return Align(
      alignment: widget.alignSkip,
      child: StreamBuilder(
        stream: _controllerFade.stream,
        initialData: 0.0,
        builder: (_, snapshot) {
          return AnimatedOpacity(
            opacity: snapshot.data,
            duration: Duration(milliseconds: 300),
            child: InkWell(
              onTap: () {
                if (widget.clickSkip != null) {
                  widget.clickSkip();
                }
                widget.finish();
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  widget.textSkip,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controllerFade.close();
    super.dispose();
  }
}
