import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/chat_message_controller.dart';
import 'package:booknest/controllers/loan_chat_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
import 'package:booknest/controllers/notification_controller.dart';
import 'package:booknest/entities/models/chat_message_model.dart';
import 'package:booknest/entities/models/loan_chat_model.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/views/notifications_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:url_launcher/url_launcher.dart';


// Widget Background para barra superior y footer
class Background extends StatefulWidget {
  final Widget child;
  final String title;
  final VoidCallback? onBack;
  final bool showNotificationIcon;
  final bool showRowIcon;
  final bool showExitIcon;
  final bool showChatIcon;

  const Background({
    super.key,
    required this.child,
    required this.title,
    this.onBack,
    this.showNotificationIcon = true,
    this.showRowIcon = true,
    this.showExitIcon = false,
    this.showChatIcon = false,
  });

  @override
  State<Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<Background> {
  late Future<int> _notificationCount;
  bool _showChatMenu = false;
  bool _showArchived = false;
  List<LoanChat> _loanChats = [];
  LoanChatController loanChatController = LoanChatController();
  String? userId;
  int? _selectedChatIndex;
  bool _isLoadingChats = false;

  final Set<int> _readChatIds = {};
  Map<int, String> _loanStates = {};
  bool _isReturningBook = false;

  @override
  void initState() {
    super.initState();
    _notificationCount = _fetchNotificationCount();
    _loadUserId();
  }

  // Función para poder abrir el enlace al correo
  Future<void> _launchUrlExternally(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('No se pudo abrir el enlace: $url'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ],
        ),
      );
    }
  }

  // Función para mostrar/ocultar chats
  void _toggleChatMenu() {
    setState(() {
      _showChatMenu = !_showChatMenu;
      _selectedChatIndex = null;
    });
  }

  // Función para obtener el id del usuario actual
  void _loadUserId() async {
    if (userId != null) return;

    final id = await AccountController().getCurrentUserId();
    if (!mounted || id == null) return;

    userId = id;

    await _loadChats(id);

    if (!mounted) return;
    setState(() {});
  }

  // Función que muestra un diálogo de confirmación para devolver un libro
  Future<bool?> _showConfirmReturnDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Estás seguro de que deseas marcar este libro como devuelto?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Sí, devolver"),
          ),
        ],
      ),
    );
  }

  // Función para actualizar el estado de una solicitud de préstamo devuelta
  Future <void> _returnPhysicalBookByUser(int loanId, int compensationLoanId) async {
    await LoanController().updateLoanStateByUser(loanId, compensationLoanId, 'Devuelto');
  }

  // Función para cargar los chats de un usuario
  Future<void> _loadChats(String currentUserId) async {

    if (currentUserId == null) {
      setState(() => _isLoadingChats = false);
      return;
    }

    final chats = await loanChatController.getUserLoanChats(currentUserId, _showArchived);
    final filteredChats = chats.where((chat) {
    final isHolder = chat.user_1 == currentUserId;
    if (isHolder && chat.deleteByHolder == true) return false;
    if (!isHolder && chat.deleteByOwner == true) return false;
    return true;
  }).toList();
    print('Loaded ${chats.length} chats for user $currentUserId');

    final Set<int> readIds = {};
    final Map<int, String> loanStates = {};

    for (var chat in chats) {
      final messages = await ChatMessageController().getMessagesForChat(chat.id, currentUserId);

      // Buscar el mensaje del usuario actual
      final myMessage = messages.where((msg) => msg.userId == currentUserId).toList();
      if (myMessage.isNotEmpty && myMessage.first.read) {
        readIds.add(chat.id);
      }

      // Obtener estado del préstamo
      final loan = await LoanController().getLoanById(chat.loanId);
      print('COMPENSATION LOAN ${loan['data']['state']}');
      loanStates[chat.loanId] = loan['data']['state'];

      final compensationLoan = await LoanController().getLoanById(chat.loanCompensationId);
      print('COMPENSATION LOAN ${compensationLoan['data']['state']}');
      loanStates[chat.loanCompensationId] = compensationLoan['data']['state'];
    }

    if (mounted) {
      setState(() {
        _loanChats = filteredChats;
        _readChatIds.addAll(readIds);
        _loanStates = loanStates;
        _isLoadingChats = false;
      });
    }
  }

  // Obtener el número de notificaciones no leídas del usuario
  Future<int> _fetchNotificationCount() async {
    final userId = await AccountController().getCurrentUserId();
    if (userId == null) return 0;

    final response = await NotificationController().getUnreadUserNotifications(userId);
    return response.length;
  }

  // Función que muestra un mensaje de confirmación para el cierre de sesión
  void _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AccountController().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  // Método para archivar/desarchivar un chat
  void _confirmArchiveToggle(LoanChat chat) async {
    final isArchived = _showArchived;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArchived ? 'Desarchivar conversación' : 'Archivar conversación'),
        content: Text(
          isArchived
              ? '¿Deseas desarchivar esta conversación del préstamo #${chat.loanId}?'
              : '¿Deseas archivar esta conversación del préstamo #${chat.loanId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isArchived ? 'Desarchivar' : 'Archivar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Llama al método adecuado de tu controlador para archivar/desarchivar
      await loanChatController.toggleArchiveStatus(chat.id, userId!, !_showArchived); // Para archivar

      // Recargar los chats actualizados
      _loadChats(userId!);
    }
  }

  // Función que muestra un diálogo de éxito en la devolución de un libro
  Future<void> showSuccessDialog(BuildContext context, int bookId) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Operación Exitosa'),
        content: const Text('¡El libro ha sido devuelto con éxito!'),
        actions: [
          TextButton(
            child: const Text('Aceptar'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  // Widget para construir el listado de chats del usuario
  Widget _buildChatList() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _selectedChatIndex == null
          ? ListView.builder(
              key: const ValueKey('chatList'),
              itemCount: _loanChats.length,
              itemBuilder: (context, index) {
                final chat = _loanChats[index];
                final isMyLoan = chat.user_1 == userId;
                final myLoanId = isMyLoan ? chat.loanId : chat.loanCompensationId;
                final myLoanState = _loanStates[myLoanId];

                return ListTile(
                  leading: GestureDetector(
                    onTap: () async {
                      final chat = _loanChats[index];
                      
                      // Actualizar estado a leído
                      await ChatMessageController().markMessageAsRead(chat.id, userId!);
                      setState(() {
                        _readChatIds.add(chat.id);
                      });
                    },
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: _readChatIds.contains(_loanChats[index].id) ? Colors.green : Colors.blue,
                    ),
                  ),
  
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Préstamo #${chat.loanId}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      if (myLoanState == 'Devuelto')
                        Row(
                          children: [
                            const Text(
                              'Devuelto',
                              style: TextStyle(
                                color: Color.fromARGB(255, 105, 105, 105),
                                fontWeight: FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('¿Eliminar chat?'),
                                    content: const Text('¿Estás seguro de que deseas eliminar tu historial de mensajes de este préstamo?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Eliminar',
                                            style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  final chatId = chat.id;
                                  await ChatMessageController().deleteMessagesByUser(chatId, userId!);
                                  await ChatMessageController().updateDeleteLoanChat(chatId, userId!);
                                  setState(() {
                                    _loanChats.removeWhere((c) => c.id == chatId);
                                    _selectedChatIndex = null;
                                  });
                                }
                              },
                              child:
                                  const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                            ),
                          ],
                        ),
                    ],
                  ),


                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => setState(() => _selectedChatIndex = index),
                  onLongPress: () => _confirmArchiveToggle(chat),
                );
              },
            )
          : FutureBuilder<List<ChatMessage>>(
              key: const ValueKey('chatMessages'),
              future: ChatMessageController().getMessagesForChat(
                _loanChats[_selectedChatIndex!].id,
                userId!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar mensajes'));
                }

                final messages = snapshot.data ?? [];
                final chat = _loanChats[_selectedChatIndex!];
                
                final isMyLoan = chat.user_1 == userId;
                final myLoanId = isMyLoan ? chat.loanId : chat.loanCompensationId;
                final myLoanState = _loanStates[myLoanId];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.chat_bubble_outline,
                        color: _readChatIds.contains(chat.id) ? Colors.green : Colors.blue,
                      ),
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Préstamo #${chat.loanId} ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            const WidgetSpan(
                              child: SizedBox(width: 30),
                            ),
                            if (myLoanState == 'Devuelto')
                              const TextSpan(
                                text: 'Devuelto',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 105, 105, 105),
                                  fontWeight: FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                          ],
                        ),
                      ),

                      trailing: const Icon(Icons.arrow_back_ios),
                     onTap: () async {
                      final chat = _loanChats[_selectedChatIndex!];

                      // Marcar como leído si no lo está
                      if (!_readChatIds.contains(chat.id)) {
                        await ChatMessageController().markMessageAsRead(chat.id, userId!);
                        setState(() {
                          _readChatIds.add(chat.id);
                        });
                      }
                      setState(() => _selectedChatIndex = null);
                    },
                      onLongPress: () => _confirmArchiveToggle(chat),
                    ),

                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.userId == userId;

                          // Determina si el préstamo asociado al usuario actual ya fue devuelto
                          final isMyLoan = chat.user_1 == userId;
                          final myLoanId = isMyLoan ? chat.loanId : chat.loanCompensationId;
                          final myLoanState = _loanStates[myLoanId];

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment:
                                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blue[100] : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Html(
                                    data: msg.content,
                                    onLinkTap: (String? url, Map<String, String> attributes, dom.Element? element) {
                                      if (url != null) {
                                        _launchUrlExternally(url);
                                      }
                                    },
                                  )
                                ),
                                // Mostramos el botón solo si el mensaje es del usuario
                                if (isMe && myLoanState != 'Devuelto') ...[
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (!mounted) return;

                                      final confirmed = await _showConfirmReturnDialog(context);
                                      if (confirmed != true || !mounted) return;

                                      setState(() => _isReturningBook = true);

                                      final chat = _loanChats[_selectedChatIndex!];

                                      if (!_readChatIds.contains(chat.id)) {
                                        await ChatMessageController().markMessageAsRead(chat.id, userId!);
                                        if (!mounted) return;
                                        setState(() {
                                          _readChatIds.add(chat.id);
                                        });
                                      }

                                      await _returnPhysicalBookByUser(chat.loanId, chat.loanCompensationId);
                                      await _loadChats(userId!);
                                      await _fetchNotificationCount();

                                      if (!mounted) return;
                                      await showSuccessDialog(context, chat.loanId);

                                      if (!mounted) return;
                                      setState(() => _isReturningBook = false);

                                    },

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF112363),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        side: const BorderSide(color: Color(0xFF112363), width: 3)),
                                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 7),
                                    ),
                                    child: const Text(
                                      "Marcar como devuelto",
                                      style: TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          );

                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          if (_showChatMenu) {
            setState(() {
              _showChatMenu = false;
            });
          }
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF112363), width: 3),
              ),
              child: Column(
                children: [
                  PreferredSize(
                    preferredSize: const Size.fromHeight(kToolbarHeight),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF112363), Color(0xFF2140AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.centerRight,
                          stops: [0.42, 0.74],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: AppBar(
                        automaticallyImplyLeading: false,
                        title: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        centerTitle: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: widget.showExitIcon
                            ? IconButton(
                                icon: const Icon(Icons.logout_sharp),
                                color: Colors.white,
                                onPressed: () => _confirmLogout(context),
                              )
                            : (widget.onBack != null && widget.showRowIcon)
                                ? IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    color: Colors.white,
                                    onPressed: () => widget.onBack?.call(),
                                  )
                                : null,
                        actions: [
                          if (widget.showChatIcon)
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              color: Colors.white,
                              onPressed: _toggleChatMenu,
                            ),
                          if (widget.showNotificationIcon)
                            FutureBuilder<int>(
                              future: _notificationCount,
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.notifications_none),
                                      color: Colors.white,
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const NotificationsView(),
                                          ),
                                        );
                                        setState(() {
                                          _notificationCount = _fetchNotificationCount();
                                        });
                                      },
                                    ),
                                    if (count > 0)
                                      Positioned(
                                        right: 6,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '$count',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                      ),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
            if (_showChatMenu)
              Positioned(
                top: kToolbarHeight + 20,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 300,
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.chat,
                                color: !_showArchived ? Colors.blue : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showArchived = false;
                                  _selectedChatIndex = null;
                                });
                                _loadChats(userId!);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.archive_outlined,
                                color: _showArchived ? Colors.blue : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showArchived = true;
                                  _selectedChatIndex = null;
                                });
                                _loadChats(userId!);
                              },
                            ),
                          ],
                        ),
                        Expanded(
                          child: _isLoadingChats || _isReturningBook
                              ? const Center(child: CircularProgressIndicator())
                              : _loanChats.isEmpty
                                  ? Center(
                                      child: Text(
                                        _showArchived
                                            ? 'No tienes conversaciones archivadas.'
                                            : 'No tienes conversaciones abiertas.',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : _buildChatList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      )
    );
  }
  
}