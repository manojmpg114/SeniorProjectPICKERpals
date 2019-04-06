import 'dart:io';
import 'package:flutter/material.dart';
import 'backend_service.dart';
import 'pickup_entry.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ListingFeed extends StatefulWidget {
  ListingFeed({Key key, this.title,this.endpoint,this.personalMode}) : super(key: key);
  final String title;
  final String endpoint;
  final List<Listing> items = [];
  final bool personalMode;
  ListingFeedState state = ListingFeedState();
  @override
  ListingFeedState createState() => state;
}



class ListingFeedState extends State<ListingFeed> {

  bool ratePress = false;
  int pageNum;
  ScrollController _controller = ScrollController();

  bool loading = false, refreshing = false;

  int rating_id = 0;
  int test = 1;
  int _radioValue = -1;

  List<Listing> getItems() {
    return widget.items;
  }
  Future<void> onRefresh() async {
    await Future.delayed(Duration(milliseconds: 3000));
    BackendService.fetchListing(
        widget.endpoint)
        .whenComplete(() {})
        .then((pick) {
      print(pick[0].item_title);
      setState(() {
        widget.items.addAll(pick);
      });
    });

    refreshing = false;
    print("loading done.");
    return null;
  }

  Future<void> onLoad() async {
    await Future.delayed(Duration(milliseconds: 500));
    BackendService.fetchListing(
        widget.endpoint)
        .whenComplete(() {})
        .then((pick) {
      print(pick[0].item_title);
      setState(() {
        widget.items.addAll(pick);
      });
    });

    loading = false;
    print("loading done.");
    return null;
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {

    pageNum = 1;
    onLoad();
    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent) {
        setState(() {
          if (!loading) {
            loading = true;
            print("now loading");
            onLoad();
            pageNum++;
          }
        });
      }
      if (_controller.offset <= _controller.position.minScrollExtent &&
          !_controller.position.outOfRange) {
        setState(() {
          print("reach the top");
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final snackBar = SnackBar(
      content: Text("Cannot Reach Server!"),
      action: SnackBarAction(label: "Ok", onPressed: () {Scaffold.of(context).hideCurrentSnackBar();}),
    );
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () {
          setState(() {
            refreshing = true;
          });
          widget.items.clear();
          return onRefresh();
        },
        child: ListView.separated(
            separatorBuilder: (context, ind) {
              return Divider(color: Colors.lightGreen,);
            },
            primary: false,
            controller: _controller,
            itemCount: widget.items.length + 1,
            itemBuilder: (context, index) {
              if (index == widget.items.length && !refreshing) {
                if (!widget.personalMode) {
                  return ListTile(
                    title: Center(child: CircularProgressIndicator(backgroundColor: Colors.green,)),
                  );
                } else {
                  return ListTile(
                    title: Center(child: Text("End of List")),
                  );
                }
              } else if (!refreshing) {
                final item = widget.items[index];
                return Dismissible(
                  key: Key(item.hashCode.toString()),
                  onDismissed: (direction) {
                    setState(() {
                      widget.items.removeAt(index);
                      Scaffold.of(context).showSnackBar(SnackBar(
                        action: SnackBarAction(
                            label: "UNDO",
                            onPressed: () {
                              setState(() {
                                widget.items.insert(index, item);
                              });
                            }),
                        content: Text(item.item_title + " dismissed"),
                      ));
                    });
                  },
                  background: Container(
                      child: Center(
                        child: Text("Y E E E E E E E E E E E E E T"),
                      ),
                      color: Colors.red),
                  secondaryBackground: Container(
                      child: Text("Y E E E E E E E E E E E T"),
                      color: Colors.green),
                  child: ListTile(
                      onLongPress: () {
                        if (widget.personalMode) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Center(child: Text('Alert')),
                                content: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children : <Widget>[
                                    Expanded(
                                      child: Text(
                                        "Are you sure you want to delete this listing?",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.red,

                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                actions: <Widget>[
                                  FlatButton(
                                      child: Text('No'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      }),
                                  FlatButton(
                                      child: Text('Yes'),
                                      onPressed: () {
                                        BackendService.deleteListing("http://ec2-3-88-8-44.compute-1.amazonaws.com:5000/deletelisting/" + item.listing_id.toString());
                                        setState(() {
                                          widget.items.removeAt(index);
                                        });
                                        Navigator.of(context).pop();
                                      })
                                ],
                              );
                            },
                          );
                        }
                      },
                      onTap: () async {
                        showDialog(
                          context: context,
                          builder: (_) => new SimpleDialog(
                            contentPadding: EdgeInsets.all(10.0),
                            children: <Widget>[
                              Text(
                                item.item_title,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24.0),
                              ),
                              Padding(padding: EdgeInsets.all(20.0)),
                              CachedNetworkImage(imageUrl: "http://ec2-3-88-8-44.compute-1.amazonaws.com:5000/images/" + item.listing_id.toString(),
                                placeholder: (context, url) => new Center(
                                    child: Container(
                                        height: 30,
                                        width: 30,
                                        child: CircularProgressIndicator(strokeWidth: 5.0,))),
                                errorWidget: (context, url, error) => new Icon(Icons.error_outline),
                              ),
                              Text("Posted by: " + item.user_id),
                              Text(
                                item.description,
                                style: TextStyle(fontSize: 15.0),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  height: 30.0,
                                  width: 10.0,
                                  child: Text(
                                    "Ok",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.0),
                                    textAlign: TextAlign.center,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.lightGreen,
                                    border: Border.all(color: Colors.black),
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                      title: Text(item.item_title),
                      subtitle: Text(item.description),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                                icon: Icon(Icons.chat),
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (_) => new AlertDialog(
                                        title: Text("Chat with Seller"),
                                        content:
                                        Text("This is where the chat would be"),
                                        actions: <Widget>[
                                          Container(
                                            height: 30.0,
                                            child: RaisedButton(
                                              child: const Text(
                                                'I Understand',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              splashColor: Colors.grey,
                                            ),
                                            decoration: BoxDecoration(
                                                color: Colors.lightGreen,
                                                border: Border.all(
                                                    color: Colors.black)),
                                          ),
                                        ],
                                      ));
                                }),
                            Visibility(
                                child: IconButton(
                                    icon: Icon(Icons.star),
                                    onPressed: () async {
                                      await showDialog(
                                          context: context,
                                          builder: (_) => RatingDialog(item: item,));
                                      setState(() {
                                        ratePress = true;
                                      });
                                    }),
                                visible: ratePress?true:true)
                          ]
                      )
                  ),
                );
              }
            }),
      ),);
  }
}

class RatingDialog extends StatefulWidget {
  RatingDialog({Key key, this.title, this.item}) : super(key: key);

  final String title;
  final Listing item;

  @override
  _RatingDialogState createState() => new _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog>{

  int _radioValue = -1;
  void _handleRadioValueChange(int value) {
    setState(() {
      _radioValue = value;
    });
    switch (_radioValue) {
      case 0:
        setState(() {
          _radioValue = 0;
        });
        break;
      case 1:
        setState(() {
          _radioValue = 1;
        });
        break;
      case 2:
        setState(() {
          _radioValue = 2;
        });
        break;
      case 3:
        setState(() {
          _radioValue = 3;
        });
        break;
      case 4:
        setState(() {
          _radioValue = 4;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
      title: Text("Rate this listing"),
      content:
      Text("Choose from 1 to 5:"),
      actions: <Widget>[
        Center(
            child: new Column(
              children: <Widget>[
                new Row(
                  children: <Widget>[
                    new Radio(value: 0, groupValue: _radioValue, onChanged: _handleRadioValueChange),
                    new Text("1"),
                    new Radio(value: 1, groupValue: _radioValue, onChanged: _handleRadioValueChange),
                    new Text("2"),
                    new Radio(value: 2, groupValue: _radioValue, onChanged: _handleRadioValueChange),
                    new Text("3"),
                    new Radio(value: 3, groupValue: _radioValue, onChanged: _handleRadioValueChange),
                    new Text("4"),
                    new Radio(value: 4, groupValue: _radioValue, onChanged: _handleRadioValueChange),
                    new Text("5"),
                  ],
                  mainAxisAlignment: MainAxisAlignment.center,),
                new RaisedButton(
                  color: Colors.lightGreen,
                  onPressed:() {Navigator.of(context).pop();
                  Rating r = new Rating(_radioValue.toString(), widget.item.listing_id.toString(), widget.item.user_id.toString());
                  BackendService.addRating(r);
                  _radioValue = -1;
                  },
                  child: Text("Ok",style: TextStyle(
                    color: Colors.black,
                  ),),),
              ],
            )
        ),
      ],
    );
  }
}