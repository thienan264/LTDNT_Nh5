namespace RentalApi.Entities;

public class RentalItem
{
    public int Id { get; set; }

    public int RentalId { get; set; }
    public Rental Rental { get; set; } = null!;

    public int DeviceId { get; set; }
    public Device Device { get; set; } = null!;

    public decimal DailyRate { get; set; }
    public int RentalDays { get; set; } = 1;
    public decimal Subtotal => DailyRate * RentalDays;

    public string? ConditionOnDelivery { get; set; }
    public string? ConditionOnReturn { get; set; }
}
