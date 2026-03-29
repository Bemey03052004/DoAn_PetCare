using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Hubs;

[Authorize]
public class ChatHub : Hub
{
    private readonly IUnitOfWork _unitOfWork;

    public ChatHub(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    private int GetCurrentUserId()
    {
        var userIdClaim = Context.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out var currentUserId))
            throw new HubException("Unauthorized");
        return currentUserId;
    }

    public async Task<int> StartDirectChat(int otherUserId)
    {
        var currentUserId = GetCurrentUserId();
        // Ensure other user exists
        var other = await _unitOfWork.Users.GetByIdAsync(otherUserId);
        if (other is null) throw new HubException("User not found");

        // Find existing room
        var rooms = await _unitOfWork.ChatRooms.FindAsync(c =>
            (c.User1Id == currentUserId && c.User2Id == otherUserId) ||
            (c.User1Id == otherUserId && c.User2Id == currentUserId));
        var room = rooms.FirstOrDefault();
        if (room == null)
        {
            room = new ChatRoom { User1Id = currentUserId, User2Id = otherUserId, CreatedAt = DateTime.UtcNow };
            room = await _unitOfWork.ChatRooms.AddAsync(room);
        }
        // Join group
        await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(room.Id));
        return room.Id;
    }

    public async Task JoinRoom(int roomId)
    {
        var currentUserId = GetCurrentUserId();
        
        // Verify that the chat room exists
        var chatRoom = await _unitOfWork.ChatRooms.GetByIdAsync(roomId);
        if (chatRoom == null)
        {
            // Log the error for debugging
            Console.WriteLine($"ChatRoom with ID {roomId} not found for user {currentUserId}");
            throw new HubException($"Chat room with ID {roomId} not found. Please ensure the chat room exists and you have permission to access it.");
        }

        // Verify that the current user is a participant in this chat room
        if (chatRoom.User1Id != currentUserId && chatRoom.User2Id != currentUserId)
        {
            throw new HubException("You are not authorized to join this chat room");
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(roomId));
        
        // Notify the user that they have successfully joined
        await Clients.Caller.SendAsync("JoinedRoom", new { roomId = roomId, message = "Successfully joined chat room" });
    }

    public async Task<int> GetOrCreateChatRoom(int otherUserId)
    {
        var currentUserId = GetCurrentUserId();
        
        // Ensure other user exists
        var other = await _unitOfWork.Users.GetByIdAsync(otherUserId);
        if (other is null) throw new HubException("User not found");

        // Find existing room
        var rooms = await _unitOfWork.ChatRooms.FindAsync(c =>
            (c.User1Id == currentUserId && c.User2Id == otherUserId) ||
            (c.User1Id == otherUserId && c.User2Id == currentUserId));
        var room = rooms.FirstOrDefault();
        
        if (room == null)
        {
            room = new ChatRoom { User1Id = currentUserId, User2Id = otherUserId, CreatedAt = DateTime.UtcNow };
            room = await _unitOfWork.ChatRooms.AddAsync(room);
            await _unitOfWork.SaveChangesAsync();
        }
        
        return room.Id;
    }

    public async Task SendMessage(int roomId, string content)
    {
        var currentUserId = GetCurrentUserId();
        if (string.IsNullOrWhiteSpace(content)) return;

        // Verify that the chat room exists
        var chatRoom = await _unitOfWork.ChatRooms.GetByIdAsync(roomId);
        if (chatRoom == null)
        {
            throw new HubException("Chat room not found");
        }

        // Verify that the current user is a participant in this chat room
        if (chatRoom.User1Id != currentUserId && chatRoom.User2Id != currentUserId)
        {
            throw new HubException("You are not authorized to send messages in this chat room");
        }

        // Persist message
        var message = new Message
        {
            ChatRoomId = roomId,
            SenderId = currentUserId,
            Content = content,
            IsRead = false,
            SentAt = DateTime.UtcNow
        };
        message = await _unitOfWork.Messages.AddAsync(message);

        var payload = new
        {
            roomId = message.ChatRoomId,
            senderId = message.SenderId,
            content = message.Content,
            sentAt = message.SentAt
        };
        await Clients.Group(GroupName(roomId)).SendAsync("ReceiveMessage", payload);
    }

    private static string GroupName(int roomId) => $"room-{roomId}";
}


