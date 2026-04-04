// // lib/src/core/globals/chat/chat_screen_loader.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:sandwich_ai/src/core/constant/appcolors.dart';
// import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/bloc.dart';
// import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/event.dart';
// import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/state.dart';
// import 'package:sandwich_ai/src/features/pos/data/model/chat_models.dart';
// import 'package:sandwich_ai/src/core/globals/chat/chat.dart';

// import 'data/model/cht_model.dart';

// class ChatScreenLoader extends StatefulWidget {
//   final Department department;
//   final String departmentKey; // matches room.department from API
//   final VoidCallback? showNavBarCallback;

//   const ChatScreenLoader({
//     super.key,
//     required this.department,
//     required this.departmentKey,
//     this.showNavBarCallback,
//   });

//   @override
//   State<ChatScreenLoader> createState() => _ChatScreenLoaderState();
// }

// class _ChatScreenLoaderState extends State<ChatScreenLoader> {
//   String? _roomId;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<ChatBloc>().add(const LoadChatRooms());
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<ChatBloc, ChatState>(
//       listener: (context, state) {
//         if (state is ChatRoomsLoaded && _roomId == null) {
//           final match = state.rooms.firstWhere(
//             (r) =>
//                 r.department?.toUpperCase() ==
//                     widget.departmentKey.toUpperCase() ||
//                 r.name.toLowerCase().contains(
//                   widget.departmentKey.toLowerCase(),
//                 ),
//             orElse: () => state.rooms.first,
//           );
//           setState(() => _roomId = match.id);
//         }
//       },
//       child: _roomId == null
//           ? const Center(child: CircularProgressIndicator(color: kPrimary))
//           : DepartmentChatScreen(
//               department: widget.department,
//               roomId: _roomId!,
//               showNavBarCallback: widget.showNavBarCallback,
//             ),
//     );
//   }
// }
