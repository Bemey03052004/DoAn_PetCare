using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities
{
    public class Message
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(ChatRoom))]
        public int ChatRoomId { get; set; }

        [JsonIgnore]
        public ChatRoom ChatRoom { get; set; } = null!;

        [ForeignKey(nameof(Sender))]
        public int SenderId { get; set; }

        [JsonIgnore]
        public User Sender { get; set; } = null!;

        [MaxLength(1000)]
        public string Content { get; set; } = "";

        public bool IsRead { get; set; } = false;
        public DateTime SentAt { get; set; } = DateTime.UtcNow;
    }
}
