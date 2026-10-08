using DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace DAL.Configurations
{
    public class PromotionConfiguration : IEntityTypeConfiguration<Promotion>
    {
        public void Configure(EntityTypeBuilder<Promotion> builder)
        {
            builder.ToTable("promotions");

            // Primary key
            builder.HasKey(p => p.PromotionId);

            builder.Property(p => p.Name)
                   .HasColumnName("name")
                   .HasColumnType("nvarchar(255)")
                   .IsRequired();

            builder.Property(p => p.PromotionId)
                   .HasColumnName("promotion_id")
                   .HasColumnType("uniqueidentifier")
                   .ValueGeneratedOnAdd()
                   .HasDefaultValueSql("NEWID()");

            // Timestamps / flags
            builder.Property(p => p.CreatedAt)
                   .HasColumnName("created_at")
                   .HasColumnType("datetime2")
                   .ValueGeneratedOnAdd()
                   .HasDefaultValueSql("GETUTCDATE()");

            builder.Property(p => p.UpdatedAt)
                   .HasColumnName("updated_at")
                   .HasColumnType("datetime2")
                   .IsRequired(false);

            builder.Property(p => p.IsDeleted)
                   .HasColumnName("is_deleted")
                   .HasColumnType("bit")
                   .HasDefaultValue(false);

            builder.Property(p => p.IsDisabled)
                   .HasColumnName("is_disabled")
                   .HasColumnType("bit")
                   .HasDefaultValue(false);

            // Type & values
            builder.Property(p => p.PromotionType)
                   .HasColumnName("promotion_type")
                   .HasColumnType("int")
                   .IsRequired();

            builder.Property(p => p.SalePrice)
                   .HasColumnName("sale_price")
                   .HasColumnType("decimal(18,2)")
                   .IsRequired(false);

            builder.Property(p => p.ThresholdPrice)
                   .HasColumnName("threshold_price")
                   .HasColumnType("decimal(18,2)")
                   .IsRequired(false);

            builder.Property(p => p.Percentage)
                   .HasColumnName("percentage")
                   .HasColumnType("decimal(18,2)")
                   .IsRequired(false);

            // Stock-related
            builder.Property(p => p.IsReservedStock)
                   .HasColumnName("is_reserved_stock")
                   .HasColumnType("bit")
                   .HasDefaultValue(true);

            builder.Property(p => p.MaxReservedStock)
                   .HasColumnName("max_reserved_stock")
                   .HasColumnType("int")
                   .IsRequired(false);

            // Time-related
            builder.Property(p => p.IsLimitedTime)
                   .HasColumnName("is_limited_time")
                   .HasColumnType("bit")
                   .HasDefaultValue(false);

            builder.Property(p => p.StartAt)
                   .HasColumnName("start_at")
                   .HasColumnType("datetime2")
                   .IsRequired(false);

            builder.Property(p => p.EndAt)
                   .HasColumnName("end_at")
                   .HasColumnType("datetime2")
                   .IsRequired(false);

            // Indexes
            builder.HasIndex(p => p.IsDeleted);
            builder.HasIndex(p => p.IsDisabled);
            builder.HasIndex(p => p.StartAt);
            builder.HasIndex(p => p.EndAt);
            builder.HasIndex(p => p.PromotionType);
        }
    }
}
