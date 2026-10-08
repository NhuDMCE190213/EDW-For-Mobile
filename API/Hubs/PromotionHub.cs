using Microsoft.AspNetCore.SignalR;
using System.Collections.Concurrent;

namespace API.Hubs
{
    public class PromotionHub : Hub
    {
        // Key: PromotionId, Value: ConnectionId
        private static readonly ConcurrentDictionary<Guid, string> _lockedPromotions = new();

        public async Task<bool> TryLockPromotion(Guid promotionId)
        {
            var connectionId = Context.ConnectionId;

            if (_lockedPromotions.TryAdd(promotionId, connectionId))
            {
                // Thông báo cho các user khác là Promotion này đã bị khóa
                await Clients.Others.SendAsync("PromotionLocked", promotionId);
                return true;
            }

            // Nếu đã bị khóa bởi người này ở connection hiện tại
            if (_lockedPromotions.TryGetValue(promotionId, out var existingConnectionId) && existingConnectionId == connectionId)
            {
                return true; 
            }

            return false; // Đã bị khóa bởi người khác
        }

        public async Task UnlockPromotion(Guid promotionId)
        {
            var connectionId = Context.ConnectionId;
            
            if (_lockedPromotions.TryGetValue(promotionId, out var ownerConnectionId) && ownerConnectionId == connectionId)
            {
                if (_lockedPromotions.TryRemove(promotionId, out _))
                {
                    await Clients.All.SendAsync("PromotionUnlocked", promotionId);
                }
            }
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var connectionId = Context.ConnectionId;
            var lockedByMe = _lockedPromotions.Where(kvp => kvp.Value == connectionId).ToList();

            foreach (var item in lockedByMe)
            {
                if (_lockedPromotions.TryRemove(item.Key, out _))
                {
                    await Clients.All.SendAsync("PromotionUnlocked", item.Key);
                }
            }

            await base.OnDisconnectedAsync(exception);
        }

        public Task<List<Guid>> GetLockedPromotions()
        {
            return Task.FromResult(_lockedPromotions.Keys.ToList());
        }
    }
}
