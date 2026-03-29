using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities
{
    public class ChatRoom
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(User1))]
        public int User1Id { get; set; }

        [JsonIgnore]
        public User User1 { get; set; } = null!;

        [ForeignKey(nameof(User2))]
        public int User2Id { get; set; }

        [JsonIgnore]
        public User User2 { get; set; } = null!;

        [JsonIgnore]
        public ICollection<Message> Messages { get; set; } = new List<Message>();

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

}
