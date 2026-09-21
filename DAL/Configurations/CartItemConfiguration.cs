using DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace DAL.Configurations
{
    public class CartItemConfiguration : IEntityTypeConfiguration<CartItem>
    {
        public void Configure(EntityTypeBuilder<CartItem> builder)
        {
            // 2. Cấu hình Khóa chính và các ràng buộc cột
            builder.HasKey(p => p.CartItemId);
            builder.Property(p => p.CustomerId).IsRequired();
            builder.Property(p => p.ProductVariantId).IsRequired();
            builder.Property(p => p.Quantity).IsRequired();
            // 3. Cấu hình quan hệ
            builder.HasOne(p => p.ProductVariant)
                .WithMany()
                .HasForeignKey(p => p.ProductVariantId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
