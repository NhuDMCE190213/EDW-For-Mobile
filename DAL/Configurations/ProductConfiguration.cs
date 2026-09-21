using DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace DAL.Configurations
{
    public class ProductConfiguration : IEntityTypeConfiguration<Product>
    {
        public void Configure(EntityTypeBuilder<Product> builder)
        {
            // 1. Cấu hình tên bảng nếu muốn khác tên DbSet có dùng naming convention nên phải comment lại tên bảng
            //builder.ToTable("Products");

            // 2. Cấu hình Khóa chính và các ràng buộc cột
            builder.HasKey(p => p.ProductId);
            builder.Property(p => p.ProductName).IsRequired().HasMaxLength(150);
            builder.Property(p => p.Brand).IsRequired().HasMaxLength(100);
            builder.Property(p => p.ImageUrl).HasColumnType("varchar(max)");
            builder.Property(p => p.CreatedAt).HasDefaultValueSql("GETUTCDATE()");

            // 3. Cấu hình quan hệ (Relationship)
            builder.HasOne(p => p.Category)
                   .WithMany()
                   .HasForeignKey(p => p.CategoryId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasMany(p => p.ProductVariants)
                   .WithOne(pv => pv.Product)
                   .HasForeignKey(pv => pv.ProductId)
                   .OnDelete(DeleteBehavior.Cascade);

            // 4. Cấu hình xóa mềm (Soft Delete)
            builder.HasQueryFilter(p => !p.IsDeleted);

            // 5. Cấu hình chỉ mục (Index)s
            builder.HasIndex(p => p.ProductName).HasDatabaseName("IX_Product_ProductName");
        }
    }
}
