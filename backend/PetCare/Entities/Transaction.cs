using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PetCare.Entities;

public class Transaction
{
    [Key]
    public int Id { get; set; }
    
    [ForeignKey(nameof(User))]
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    
    public decimal Amount { get; set; }
    public string Type { get; set; } = ""; // "Boarding", "Sale", "Adoption"
    public string Status { get; set; } = ""; // "Pending", "Completed", "Failed", "Cancelled"
    public string Description { get; set; } = "";
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}

