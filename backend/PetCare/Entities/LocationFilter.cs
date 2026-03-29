namespace PetCare.Entities
{
    public class LocationFilter
    {
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public double? RadiusKm { get; set; } = 10; // bán kính tìm kiếm
    }

}
