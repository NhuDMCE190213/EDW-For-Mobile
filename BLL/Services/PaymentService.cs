using BLL.Settings;
using Microsoft.Extensions.Options;

namespace BLL.Services
{
    public class PaymentService
    {
        private readonly VnpaySettings _vnpaySettings;

        public PaymentService(IOptions<VnpaySettings> vnpaySettings)
        {
            _vnpaySettings = vnpaySettings.Value;
        }
    }
}
