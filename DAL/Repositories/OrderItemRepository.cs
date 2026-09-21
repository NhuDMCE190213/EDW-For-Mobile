using DAL.Data;
using DAL.Models;
using DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DAL.Repositories
{
    public class OrderItemRepository : IOrderItemRepository
    {
        private readonly AppDbContext _context;

        public OrderItemRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<List<OrderItem>> GetAllOrderItemsAsync()
        {
            return await _context.OrderItems
                .Include(oi => oi.ProductVariant)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<OrderItem?> GetOrderItemByIdAsync(int orderItemId)
        {
            return await _context.OrderItems
                .Include(oi => oi.ProductVariant)
                .FirstOrDefaultAsync(oi => oi.OrderItemId == orderItemId);
        }

        public async Task<List<OrderItem>> GetOrderItemsByOrderIdAsync(Guid orderId)
        {
            return await _context.OrderItems
                .Where(oi => oi.OrderId == orderId)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<List<OrderItem>> GetOrderItemsWithProductVariantAsync(Guid orderId)
        {
            return await _context.OrderItems
                .Include(oi => oi.ProductVariant)
                .ThenInclude(pv => pv.Product)
                .Where(oi => oi.OrderId == orderId)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<OrderItem> CreateOrderItemAsync(OrderItem orderItem)
        {
            _context.OrderItems.Add(orderItem);
            await _context.SaveChangesAsync();
            return orderItem;
        }

        public async Task<bool> UpdateOrderItemAsync(OrderItem orderItem)
        {
            var existingOrderItem = await _context.OrderItems.FindAsync(orderItem.OrderItemId);
            if (existingOrderItem != null)
            {
                existingOrderItem.Update(orderItem.Quantity, orderItem.PriceAtPurchase);
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }

        public async Task<bool> DeleteOrderItemAsync(int orderItemId)
        {
            var orderItem = await _context.OrderItems.FirstOrDefaultAsync(oi => oi.OrderItemId == orderItemId);
            if (orderItem != null)
            {
                orderItem.Delete();
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }

        public async Task<bool> DeleteOrderItemsByOrderIdAsync(Guid orderId)
        {
            var orderItems = await _context.OrderItems
                .Where(oi => oi.OrderId == orderId)
                .ToListAsync();

            foreach (var orderItem in orderItems)
            {
                orderItem.Delete();
            }

            await _context.SaveChangesAsync();
            return true;
        }
    }
}
