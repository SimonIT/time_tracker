import 'dart:async';

import 'package:duration/duration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_typeahead/cupertino_flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:time_tracker/api.dart' as api;
import 'package:time_tracker/data.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TrackerState state;

  TextEditingController _project = TextEditingController();
  TextEditingController _task = TextEditingController();
  TextEditingController _comment = TextEditingController();
  TextEditingController _company = TextEditingController();
  TextEditingController _user = TextEditingController();
  TextEditingController _password = TextEditingController();

  _MyAppState() {
    _refresh();
  }

  void _refresh() async {
    await api.authenticate();
    api.loadTrackerState().then((TrackerState state) {
      if (state == null) {
      } else {
        setState(() {
          this.state = state;
          updateInputs();
        });
      }
    });
  }

  void updateInputs() {
    if (state.project is StateProject) {
      _project.text = "${state.project.customer}: ${state.project.name}";
    } else {
      _project.text = "";
    }
    _task.text = state.task_name;
    _comment.text = state.comment;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Papierkram.de TimeTracker',
      theme: CupertinoThemeData(
        primaryColor: Color.fromRGBO(185, 213, 222, 1),
        primaryContrastingColor: Color.fromRGBO(0, 59, 78, 1),
        barBackgroundColor: Color.fromRGBO(0, 59, 78, 1),
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            color: CupertinoColors.white,
            fontSize: 17,
          ),
        ),
        scaffoldBackgroundColor: Color.fromRGBO(0, 102, 136, 1),
      ),
      home: state != null
          ? CupertinoTabScaffold(
              tabBar: CupertinoTabBar(
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(
                      IconData(
                        0xF2FD,
                        fontFamily: CupertinoIcons.iconFont,
                        fontPackage: CupertinoIcons.iconFontPackage,
                        matchTextDirection: true,
                      ),
                    ),
                    title: Text('Tracken'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.pen),
                    title: Text('Zeiterfassung'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.clock),
                    title: Text('Buchungen'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.settings),
                    title: Text('Zugangsdaten'),
                  ),
                ],
              ),
              tabBuilder: (BuildContext context, int index) {
                switch (index) {
                  case 0:
                    return CupertinoTabView(
                      builder: (BuildContext context) {
                        return Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Text(state.task_name),
                                      Text(
                                        state.project is StateProject
                                            ? "${state.project.customer}:"
                                                " ${state.project.name}"
                                            : "",
                                      ),
                                    ],
                                  ),
                                ),
                                TrackingLabel(state),
                              ],
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                            TrackingButton(
                              onPressed: () => track(context),
                              tracking: state.getStatus(),
                            ),
                          ],
                          mainAxisAlignment: MainAxisAlignment.center,
                        );
                      },
                    );
                  case 1:
                    return CupertinoTabView(
                      builder: (BuildContext context) {
                        return ListView(
                          physics: ClampingScrollPhysics(),
                          children: <Widget>[
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Zeiterfassung",
                                  textScaleFactor: 2,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoTypeAheadField(
                                textFieldConfiguration: CupertinoTextFieldConfiguration(
                                  enabled: state.project == null,
                                  controller: _project,
                                  clearButtonMode: OverlayVisibilityMode.editing,
                                  placeholder: "Kunde/Projekt",
                                  autocorrect: false,
                                  maxLines: 1,
                                ),
                                itemBuilder: (BuildContext context, Project itemData) {
                                  return Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(
                                      "${itemData.customer.name}: ${itemData.name}",
                                      style: TextStyle(color: CupertinoTheme.of(context).primaryContrastingColor),
                                    ),
                                  );
                                },
                                onSuggestionSelected: (Project suggestion) {
                                  setState(() {
                                    state.setProject(suggestion);
                                    api.setTrackerState(state);
                                    updateInputs();
                                  });
                                },
                                suggestionsCallback: (String pattern) async {
                                  return await api.loadProjects(searchPattern: pattern);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoTextField(
                                controller: _task,
                                enabled: state.project != null,
                                placeholder: "Aufgabe",
                                autocorrect: false,
                                maxLines: 1,
                                onChanged: (String text) {
                                  state.task_name = text;
                                  api.setTrackerState(state);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoTextField(
                                controller: _comment,
                                placeholder: "Kommentar",
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                onChanged: (String text) {
                                  state.comment = text;
                                  api.setTrackerState(state);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: state.getStatus()
                                      ? [
                                          BoxShadow(color: Color.fromRGBO(209, 208, 203, 1)),
                                        ]
                                      : [],
                                  border: Border(
                                    top: BorderSide(
                                      color: CupertinoColors.lightBackgroundGray,
                                      style: BorderStyle.solid,
                                      width: 0.0,
                                    ),
                                    bottom: BorderSide(
                                      color: CupertinoColors.lightBackgroundGray,
                                      style: BorderStyle.solid,
                                      width: 0.0,
                                    ),
                                    left: BorderSide(
                                      color: CupertinoColors.lightBackgroundGray,
                                      style: BorderStyle.solid,
                                      width: 0.0,
                                    ),
                                    right: BorderSide(
                                      color: CupertinoColors.lightBackgroundGray,
                                      style: BorderStyle.solid,
                                      width: 0.0,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            IconData(
                                              0xF2D1,
                                              fontFamily: CupertinoIcons.iconFont,
                                              fontPackage: CupertinoIcons.iconFontPackage,
                                              matchTextDirection: true,
                                            ),
                                            color: CupertinoColors.white,
                                          ),
                                          GestureDetector(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text(DateFormat("dd.MM.yyyy").format(state.getStartedAt())),
                                            ),
                                            onTap: () {
                                              if (!state.getStatus()) {
                                                showCupertinoModalPopup<void>(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return _buildBottomPicker(
                                                      CupertinoDatePicker(
                                                        mode: CupertinoDatePickerMode.date,
                                                        initialDateTime: state.getStartedAt(),
                                                        use24hFormat: true,
                                                        onDateTimeChanged: (DateTime newDateTime) {
                                                          setState(() {
                                                            state.setManualTimeChange(true);
                                                            state.setPausedDuration(Duration());
                                                            state.setStartedAt(newDateTime);
                                                            if (!state.hasStoppedTime())
                                                              state.setStoppedAt(DateTime.now());
                                                            api.setTrackerState(state);
                                                          });
                                                        },
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            CupertinoIcons.time_solid,
                                            color: CupertinoColors.white,
                                          ),
                                          GestureDetector(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text(DateFormat("HH:mm").format(state.getStartedAt())),
                                            ),
                                            onTap: () {
                                              if (!state.getStatus()) {
                                                showCupertinoModalPopup<void>(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return _buildBottomPicker(
                                                      CupertinoDatePicker(
                                                        mode: CupertinoDatePickerMode.time,
                                                        initialDateTime: state.getStartedAt(),
                                                        use24hFormat: true,
                                                        onDateTimeChanged: (DateTime newDateTime) {
                                                          setState(() {
                                                            state.setManualTimeChange(true);
                                                            state.setPausedDuration(Duration());
                                                            state.setStartedAt(newDateTime);
                                                            if (!state.hasStoppedTime())
                                                              state.setStoppedAt(DateTime.now());
                                                            api.setTrackerState(state);
                                                          });
                                                        },
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text("bis"),
                                          ),
                                          GestureDetector(
                                            child: Text(DateFormat("HH:mm").format(state.getEndedAt())),
                                            onTap: () {
                                              if (!state.getStatus()) {
                                                showCupertinoModalPopup<void>(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return _buildBottomPicker(
                                                      CupertinoDatePicker(
                                                        mode: CupertinoDatePickerMode.time,
                                                        minimumDate: state.getStartedAt(),
                                                        initialDateTime: state.getEndedAt(),
                                                        use24hFormat: true,
                                                        onDateTimeChanged: (DateTime newDateTime) {
                                                          setState(() {
                                                            state.setManualTimeChange(true);
                                                            state.setPausedDuration(Duration());
                                                            if (!state.hasStartedTime())
                                                              state.setStartedAt(DateTime.now());
                                                            state.setStoppedAt(newDateTime);
                                                            api.setTrackerState(state);
                                                          });
                                                        },
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: <Widget>[
                                  TrackingLabel(state),
                                  TrackingButton(
                                    onPressed: () => track(context),
                                    tracking: state.getStatus(),
                                  ),
                                ],
                                mainAxisAlignment: MainAxisAlignment.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoButton.filled(
                                child: Text("Buchen"),
                                onPressed: () async {
                                  await api.postTrackedTime(state);
                                  state.empty();
                                  api.setTrackerState(state);
                                  _refresh();
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoButton.filled(
                                child: Text("Verwerfen"),
                                onPressed: () {
                                  setState(() {
                                    state.empty();
                                    api.setTrackerState(state);
                                    updateInputs();
                                  });
                                },
                              ),
                            )
                          ],
                        );
                      },
                    );
                  case 2:
                    return CupertinoTabView(
                      builder: (BuildContext context) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16.0,
                          ),
                          child: ListView.builder(
                            physics: ClampingScrollPhysics(),
                            /*children: <Widget>[
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    width: 1,
                                    color: CupertinoColors.lightBackgroundGray,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(9.0),
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      "Heute",
                                      textScaleFactor: 1.5,
                                    ),
                                    Text("19m"),
                                  ],
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    width: 1,
                                    color: CupertinoColors.lightBackgroundGray,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(9.0),
                                child: Text(
                                  "Frühere Einträge",
                                  textScaleFactor: 1.5,
                                ),
                              ),
                            ),
                          ],*/
                            itemBuilder: (BuildContext context, int index) {
                              Entry recent = state.recent_entries[index];
                              return RecentTasks(
                                entry: recent,
                                onPressed: () {
                                  setState(() {
                                    state.setToEntry(recent);
                                    updateInputs();
                                  });
                                },
                              );
                            },
                            itemCount: state.recent_entries.length,
                          ),
                        );
                      },
                    );
                  case 3:
                    return CupertinoTabView(
                      builder: (BuildContext context) {
                        return CredentialsPage(_company, _user, _password, _refresh);
                      },
                    );
                }
              },
            )
          : CupertinoPageScaffold(
              child: CredentialsPage(_company, _user, _password, _refresh),
            ),
    );
  }

  void track(BuildContext context) {
    setState(() {
      if (state.task_name.isNotEmpty) {
        if (state.getManualTimeChange()) {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) => CupertinoAlertDialog(
                  title: Icon(
                    IconData(
                      0xF3BC,
                      fontFamily: CupertinoIcons.iconFont,
                      fontPackage: CupertinoIcons.iconFontPackage,
                      matchTextDirection: true,
                    ),
                    color: CupertinoTheme.of(context).primaryContrastingColor,
                  ),
                  content: Text("Sollen die manuellen Änderungen zurückgesetzt werden?"),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: Text(
                        "OK",
                      ),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop("OK");
                        state.setManualTimeChange(false);
                        track(context);
                      },
                    ),
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: Text(
                        "Abbrechen",
                      ),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop("Cancel");
                      },
                    )
                  ],
                ),
          );
        } else {
          state.setStatus(!state.getStatus());
          if (state.getStatus()) {
            if (!state.hasStartedTime()) {
              state.setStartedAt(DateTime.now());
              api.setTrackerState(state);
            } else {
              state.setPausedDuration(state.getPausedDuration() + DateTime.now().difference(state.getEndedAt()));
              state.stopped_at = "0";
              state.ended_at = "0";
              api.setTrackerState(state);
            }
          } else {
            state.setStoppedAt(DateTime.now());
            api.setTrackerState(state);
          }
        }
      } else {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
                title: Icon(
                  IconData(
                    0xF3BC,
                    fontFamily: CupertinoIcons.iconFont,
                    fontPackage: CupertinoIcons.iconFontPackage,
                    matchTextDirection: true,
                  ),
                  color: CupertinoTheme.of(context).primaryContrastingColor,
                ),
                content: Text("Es wurde noch kein Projekt bzw. Task ausgewählt."),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: Text(
                      "OK",
                    ),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop("OK");
                    },
                  )
                ],
              ),
        );
      }
    });
  }
}

class CredentialsPage extends StatelessWidget {
  final TextEditingController _company;
  final TextEditingController _user;
  final TextEditingController _password;
  final Function _refresh;

  CredentialsPage(this._company, this._user, this._password, this._refresh, {Key key}) : super(key: key) {
    api.loadCredentials().then((bool success) {
      if (success) {
        _company.text = api.authCompany;
        _user.text = api.authUsername;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: ListView(
        physics: ClampingScrollPhysics(),
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Ihre Papierkram.de Zugangsdaten",
                textScaleFactor: 2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoTextField(
              controller: _company,
              placeholder: "Firmen ID",
              autocorrect: false,
              maxLines: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoTextField(
              controller: _user,
              placeholder: "Nutzer",
              autocorrect: false,
              maxLines: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoTextField(
              controller: _password,
              placeholder: "Passwort",
              autocorrect: false,
              maxLines: 1,
              obscureText: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoButton.filled(
              child: Text("Speichern"),
              onPressed: () async {
                if (_password.text.isNotEmpty) {
                  await api.saveSettingsCheckToken(_company.text, _user.text, _password.text);
                  this._refresh();
                }
              },
            ),
          )
        ],
      ),
    );
  }
}

class RecentTasks extends StatelessWidget {
  final Entry entry;
  final Function onPressed;

  RecentTasks({
    @required this.entry,
    @required this.onPressed,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(9.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  "${entry.customer_name}: ${entry.project_name}",
                  textScaleFactor: 0.75,
                  style: TextStyle(
                    color: CupertinoColors.lightBackgroundGray,
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text(entry.task_name),
                Text(
                  prettyDuration(
                    Duration(
                      seconds: entry.task_duration,
                    ),
                    abbreviated: true,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            )
          ],
        ),
      ),
      behavior: HitTestBehavior.translucent,
      onTap: onPressed,
    );
  }
}

class TrackingButton extends StatelessWidget {
  final Function onPressed;
  final bool tracking;

  const TrackingButton({
    @required this.onPressed,
    @required this.tracking,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CupertinoButton(
        child: tracking ? Icon(CupertinoIcons.pause_solid) : Icon(CupertinoIcons.play_arrow_solid),
        onPressed: onPressed,
        color: tracking ? Color.fromRGBO(218, 78, 73, 1) : Color.fromRGBO(91, 182, 91, 1),
      ),
    );
  }
}

class TrackingLabel extends StatefulWidget {
  final TrackerState state;

  const TrackingLabel(this.state, {Key key}) : super(key: key);

  @override
  _TrackingLabelState createState() => _TrackingLabelState();
}

class _TrackingLabelState extends State<TrackingLabel> {
  Duration d = Duration();

  _TrackingLabelState() {
    Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (widget.state.getStatus()) {
          d = DateTime.now().difference(widget.state.getStartedAt()) - widget.state.getPausedDuration();
        } else {
          d = widget.state.getStoppedAt().difference(widget.state.getStartedAt()) - widget.state.getPausedDuration();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      prettyDuration(
        d,
        abbreviated: true,
      ),
      textScaleFactor: 1.5,
    );
  }
}

Widget _buildBottomPicker(Widget picker) {
  return Container(
    height: 216.0,
    padding: const EdgeInsets.only(top: 6.0),
    color: CupertinoColors.white,
    child: DefaultTextStyle(
      style: const TextStyle(
        color: CupertinoColors.black,
        fontSize: 22.0,
      ),
      child: GestureDetector(
        onTap: () {},
        child: SafeArea(
          top: false,
          child: picker,
        ),
      ),
    ),
  );
}
