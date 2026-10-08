using DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace DAL.Configurations
{
    public class ProductVariantConfiguration : IEntityTypeConfiguration<ProductVariant>
    {
        public void Configure(EntityTypeBuilder<ProductVariant> builder)
        {
            // Keep the runtime mapping aligned with the existing InitData migration.
            builder.ToTable("product_variants");
            builder.HasKey(pv => pv.ProductVariantId);
            builder.Property(pv => pv.Sku).IsRequired().HasMaxLength(50);
            //builder.Property(pv => pv.ProductCode).IsRequired().HasMaxLength(50);
            builder.Property(pv => pv.Color).IsRequired().HasMaxLength(50);
            builder.Property(pv => pv.Cpu).HasMaxLength(100);
            builder.Property(pv => pv.Ram).HasMaxLength(50);
            builder.Property(pv => pv.Storage).HasMaxLength(50);
            builder.Property(pv => pv.ScreenSize).HasMaxLength(50);
            builder.Property(pv => pv.Price).IsRequired().HasColumnType("decimal(18,2)");
            builder.Property(pv => pv.StockQuantity).IsRequired();
            builder.Property(pv => pv.ImageUrl).HasMaxLength(200);
            builder.Property(pv => pv.PromotionId);

            // Cấu hình quan hệ với Promotion
            builder.HasOne(pv => pv.Promotion)
                   .WithMany()
                   .HasForeignKey(pv => pv.PromotionId)
                   .HasConstraintName("fk_product_variants_promotions_promotion_id");

            // Check xóa mềm
            builder.HasQueryFilter(pv => !pv.IsDeleted);

            // Thêm index để tăng hiệu suất tìm kiếm theo SKU
            builder.HasIndex(pv => pv.Sku).IsUnique();
            builder.HasIndex(pv => pv.Price);
        }
    }
}
