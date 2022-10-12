

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_kom/module_orders/request/accept_order_request/accept_order_request.dart';
import 'package:my_kom/module_orders/request/order/order_request.dart';
import 'package:my_kom/module_orders/response/order_details/order_details_response.dart';
import 'package:my_kom/module_orders/response/order_status/order_status_response.dart';


class OrderRepository {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ///
  late  Query<Map<String, dynamic>> _pendingOrdersQuery ;
  late  Query<Map<String, dynamic>> _finishedOrdersQuery ;
  // OrderRepository(
  //   this._apiClient,
  //   this._authService,
  // );

  Future<DocumentSnapshot> addNewOrder(CreateOrderRequest orderRequest) async {
     try{

       /// Get a new write batch
       final batch = _firestore.batch();

       /// Set Main Detail For Anew Order
       var mainOrderRef = _firestore.collection('orders').doc();
       batch.set(mainOrderRef, orderRequest.mainDetailsToJson());

       /// Set More Detail For Anew Order
       var moreOrderRef = _firestore.collection('orders').doc(mainOrderRef.id).collection('details').doc();
       batch.set(moreOrderRef, orderRequest.moreDetailsToJson());

      /// Commit the batch
       batch.commit().then((_) {
         print('Data Success Commit !!!!!!');
       }).catchError((e){
         throw Exception();
       });

       ///
       DocumentSnapshot d =  await _firestore.collection('orders').doc(mainOrderRef.id).get().catchError((e){
         print('Order Is Created , But Error In Get Information . !!!!');
       });


     return d;
    }catch(e){
      throw Exception('Error in set data !');
    }
  }

  Future<OrderDetailResponse?> getOrderDetails(String orderId) async {
    try{
      return await _firestore.collection('orders').doc(orderId).collection('details').get().then((value) {
         Map <String ,dynamic> result = value.docs[0].data() ;
         result['id'] = orderId;
         OrderDetailResponse r =   OrderDetailResponse.fromJson(result) ;
         return r;
   });

    }catch(e){
      print(e);
      throw Exception('Error in get order detail  !');
    }
  }

  Future<OrderStatusResponse?> getTrackingDetails(String orderId) async {
    try{
      return await _firestore.collection('orders').doc(orderId).get().then((value) {
        Map <String ,dynamic> result =value.data() as  Map <String ,dynamic>;
        result['id'] = orderId;

        OrderStatusResponse r =   OrderStatusResponse.fromJson(result) ;
        return r;
      });

    }catch(e){
      print(e);
      throw Exception('Error in get tracking details !');
    }
  }



  Stream<QuerySnapshot> getFirstBatchPendingMyOrders(
      {required String uid})  {
    try{
      _pendingOrdersQuery = _firestore.collection('orders').where('userId',isEqualTo: uid).where('status',isNotEqualTo: 'FINISHED').orderBy('status').orderBy('customer_order_id',descending: true);
      return  _pendingOrdersQuery.limit(4).snapshots();
    }catch(e){
      print(e);
      throw Exception('Error in get my order !');
    }
  }


 Future<QuerySnapshot<Map<String, dynamic>>> getNextBatchPendingMyOrders(
    {required String uid,required DocumentSnapshot<Object?> offset})  {

      try{
         return  _pendingOrdersQuery.limit(4).startAfterDocument(offset).get();
      }catch(e){
        print(e);
        throw Exception('Error in get my order !');
     }
}



  Stream<QuerySnapshot> getFirstBatchFinishedMyOrders(
      {required String uid})  {
    try{
      _finishedOrdersQuery = _firestore.collection('orders').where('userId',isEqualTo: uid).where('status',isEqualTo: 'FINISHED').orderBy('customer_order_id',descending: true);
      return  _finishedOrdersQuery.limit(10).snapshots();
    }catch(e){
      print(e);
      throw Exception('Error in get my order !');
    }
  }


  Future<QuerySnapshot<Map<String, dynamic>>> getNextBatchFinishedMyOrders(
      {required String uid,required DocumentSnapshot<Object?> offset})  {

    try{
      return  _finishedOrdersQuery.limit(10).startAfterDocument(offset).get();
    }catch(e){
      print(e);
      throw Exception('Error in get my order !');
    }
  }


  Stream<QuerySnapshot> getNotifications(String uid)  {

    try{
      return   _firestore.collection('offers').snapshots();
    }catch(e){
      throw Exception('Error in get notifications !');
    }
  }
  
 Future<bool> deleteOrder(String orderId)async {
    print('delete order by order id: ${orderId}');
    try{
      await _firestore.collection('orders').doc(orderId).delete();
     //  await Future.wait([
     //    //_firestore.collection('orders').doc(orderId).collection('details').

 //  ]);
      return true;
    }catch(e){
      print('tag : repository , message : Error in deleted !!! ');
      return false;
    }
 }

  Future<OrderStatusResponse?> updateOrder(updateOrderRequest request) async{
    try{
       await _firestore.collection('orders').doc(request.orderID).update(request.toJson()).then((value) {
       });

  }catch(e){
  print(e);
  throw Exception('Error in update data !');
  }
  }

  // Future<int> getOrdersSize() async{
  //   try{
  //     int size = 0;
  //   var list = await  _firestore.collection('orders').snapshots().toList();
  //  return list.length;
  //
  //   }catch(e){
  //
  //     return 0;
  //   }
  // }

  getOwnerOrders() {
    try{
      return   _firestore.collection('orders').snapshots();
    }catch(e){
      throw Exception('Error in get data !');
    }
  }

 Future<int?> generateOrderID()async {
    try{
         var docs = await _firestore.collection('utils').get();
         DocumentReference _ref =  docs.docs[0].reference;

      return _firestore.runTransaction( (Transaction transaction) async {
          DocumentSnapshot _document = await transaction.get(_ref);

            Map _m =_document.data() as Map;
            Map<String , dynamic> map = {'doc_id':_document.id,
              'order_id':_m['customer_order_id']
            };

           await transaction.update(_ref, {
              'customer_order_id': map['order_id']+1
            });

           return map['order_id']+1;

      });
     // Map<String , dynamic> map =  await _firestore.collection('utils').get().then((value) {
     //    return {'doc_id':value.docs[0].id,
     //    'order_id':value.docs[0].data()['customer_order_id']
     //    };
     //  });
     //
     //   await _firestore.collection('utils').doc( map['doc_id']).update({
     //   'customer_order_id': map['order_id']+1
     // });
     //   int id = map['order_id']+1;
     //   return id ;
    }catch(e){
      print('exception in generated customer id');
      return null;
    }

 }




  // Future<OrderDetailsResponse?> updateOrder(UpdateOrderRequest request) async {
  //   // var token = await _authService.getToken();
  //   // dynamic response = await _apiClient.put(
  //   //   '${Urls.CAPTAIN_ORDER_UPDATE_API}',
  //   //   request.toJson(),
  //   //   headers: {'Authorization': 'Bearer ' + token},
  //   // );
  //
  //   // if (response == null) return null;
  //
  //   // return OrderDetailsResponse.fromJson(response);
  //   return null;
  // }
}