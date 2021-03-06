import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:ggsipu_notice/ui/widgets/about.dart';
import 'package:ggsipu_notice/ui/widgets/noticeTile.dart';
import 'package:ggsipu_notice/ui/widgets/themeswitch.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool priorityCheck = false;
  int limit = 8;
  bool loading = false;
  ScrollController controller = ScrollController();
  @override
  void initState() {
    super.initState();
    controller.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      print("at the end of list");
      setState(() {
        limit = limit + 8;
      });
      print(limit);
    }
  }

  @override
  Widget build(BuildContext context) {
    Query notices = FirebaseFirestore.instance
        .collection('notices')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    return CupertinoPageScaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        controller: controller,
        slivers: [
          CupertinoSliverNavigationBar(
            leading: AboutButton(),
            trailing: ThemeSwitchButton(),
            border: null,
            automaticallyImplyLeading: false,
            padding: EdgeInsetsDirectional.zero,
            largeTitle: Text(
              'Notices',
              style: TextStyle(
                color: NeumorphicTheme.defaultTextColor(context),
              ),
            ),
            backgroundColor: NeumorphicTheme.accentColor(context),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () {
              setState(() {
                limit = 8;
              });
              return Future<void>.delayed(const Duration(seconds: 1))
                ..then<void>((_) {});
            },
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 5, 8),
                    child: Row(
                      children: [
                        Text(
                          priorityCheck ? "Priority" : "Latest",
                          style: TextStyle(
                            color: NeumorphicTheme.defaultTextColor(context)
                                .withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        Spacer(),
                        ClipOval(
                          child: Material(
                            elevation: 0,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(500),
                            child: IconButton(
                              icon: priorityCheck
                                  ? Icon(CupertinoIcons.star)
                                  : Icon(CupertinoIcons.time),
                              color: NeumorphicTheme.defaultTextColor(context)
                                  .withOpacity(0.8),
                              onPressed: () {
                                setState(() {
                                  priorityCheck = !priorityCheck;
                                });
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
              childCount: 1,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: notices.snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                loading = true;
              } else {
                loading = false;
              }
              if (snapshot.hasError) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 200.0,
                          width: MediaQuery.of(context).size.width,
                          child: Center(
                            child: Icon(
                              CupertinoIcons.multiply_circle,
                              color: NeumorphicTheme.defaultTextColor(context),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: 1,
                  ),
                );
              }
              if (snapshot.hasData) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      if (index == snapshot.data.docs.length) {
                        return SizedBox(
                          height: 100,
                          width: 100,
                          child: Center(
                              child: loading
                                  ? CupertinoActivityIndicator(
                                      animating: true,
                                      radius: 14,
                                    )
                                  : Container()),
                        );
                      }
                      final bool download = snapshot.data.docs[index]['url']
                          .toString()
                          .toLowerCase()
                          .contains(".pdf");
                      if (priorityCheck) {
                        if (snapshot.data.docs[index]['priority']) {
                          return NoticeTile(
                            download: download,
                            document: snapshot.data.docs[index],
                          );
                        }
                      } else {
                        return NoticeTile(
                          download: download,
                          document: snapshot.data.docs[index],
                        );
                      }
                      return Container();
                    },
                    childCount: snapshot.data.docs.length + 1,
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 200.0,
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: CupertinoActivityIndicator(
                            animating: true,
                            radius: 20,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: 1,
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
