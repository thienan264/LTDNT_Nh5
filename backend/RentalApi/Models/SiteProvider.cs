namespace RentalApi.Models;

// Giống SiteProvider trong bài mẫu TrekBikes của thầy.
public class SiteProvider : BaseProvider
{
    public SiteProvider(IConfiguration configuration)
        : base(configuration) { }

    private CategoryRepository? category;
    private DeviceRepository? device;
    private MemberRepository? member;
    private UnitRepository? unit;
    private RentalRepository? rental;
    public CategoryRepository Category => category ??= new(Connection);
    public DeviceRepository Device => device ??= new(Connection);
    public MemberRepository Member => member ??= new(Connection);
    public UnitRepository Unit => unit ??= new(Connection);
    public RentalRepository Rental => rental ??= new(Connection);
}
