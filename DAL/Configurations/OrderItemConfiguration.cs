using DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace DAL.Configurations
{
    public class OrderItemConfiguration : IEntityTypeConfiguration<OrderItem>
    {
        public void Configure(EntityTypeBuilder<OrderItem> builder)
        {
            // Configure primary key
            builder.HasKey(oi => oi.OrderItemId);

            // Configure OrderItemId as identity
            builder.Property(oi => oi.OrderItemId)
                .UseIdentityColumn(1, 1);

            builder.Property(oi => oi.OrderId)
                .IsRequired();

            builder.Property(oi => oi.ProductVariantId)
                .IsRequired();

            builder.Property(oi => oi.Quantity)
                   .IsRequired();

            builder.ToTable(t =>
            {
                t.HasCheckConstraint(
                    "CK_OrderItem_Quantity_Positive",
                    "[quantity] > 0");
            });

            builder.Property(oi => oi.PriceAtPurchase)
                .IsRequired()
                .HasColumnType("decimal(18,2)");

            builder.Property(oi => oi.CreatedAt)
                .IsRequired()
                .HasDefaultValueSql("GETDATE()");

            builder.Property(oi => oi.UpdatedAt)
                .HasDefaultValueSql("GETDATE()");

            builder.Property(oi => oi.IsDeleted)
                .HasDefaultValue(false);

            // Configure indexes
            builder.HasIndex(oi => oi.OrderId)
                .HasDatabaseName("ix_order_items_order_id");

            builder.HasIndex(oi => oi.ProductVariantId)
                .HasDatabaseName("ix_order_items_product_variant_id");

            // Configure relationships
            builder.HasOne(oi => oi.Order)
                .WithMany(o => o.OrderItems)
                .HasForeignKey(oi => oi.OrderId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(oi => oi.ProductVariant)
                .WithMany()
                .HasForeignKey(oi => oi.ProductVariantId)
                .OnDelete(DeleteBehavior.Restrict);

            // Configure soft delete
            builder.HasQueryFilter(oi => !oi.IsDeleted);
        }
    }
}
