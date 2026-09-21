using DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace DAL.Configurations
{
    public class OrderConfiguration : IEntityTypeConfiguration<Order>
    {
        public void Configure(EntityTypeBuilder<Order> builder)
        {
            // Configure primary key
            builder.HasKey(o => o.OrderId);

            // Configure properties
            builder.Property(o => o.OrderId)
                .HasDefaultValueSql("NEWID()");

            builder.Property(o => o.CustomerId)
                .IsRequired();

            builder.ToTable(t =>
            {
                t.HasCheckConstraint(
                    "CK_Order_TotalAmount_NonNegative",
                    "[total_amount] >= 0");
            });

            builder.Property(o => o.TotalAmount)
                   .IsRequired()
                   .HasColumnType("decimal(18,2)");



            builder.Property(o => o.Status)
                .IsRequired()
                .HasMaxLength(20)
                .HasDefaultValue("Pending");

            builder.Property(o => o.CreatedAt)
                .IsRequired()
                .HasDefaultValueSql("GETDATE()");

            builder.Property(o => o.UpdatedAt)
                .HasDefaultValueSql("GETDATE()");

            builder.Property(o => o.IsDeleted)
                .HasDefaultValue(false);

            // Configure indexes
            builder.HasIndex(o => new { o.Status, o.CreatedAt })
                .HasDatabaseName("ix_orders_status_created_at");

            builder.HasIndex(o => o.CustomerId)
                .HasDatabaseName("ix_orders_customer_id");

            builder.HasIndex(o => o.CreatedAt)
                .HasDatabaseName("ix_orders_created_at");

            // Configure relationships
            builder.HasMany(o => o.OrderItems)
                .WithOne(oi => oi.Order)
                .HasForeignKey(oi => oi.OrderId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(o => o.Customer)
                .WithMany()
                .HasForeignKey(o => o.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);

            // Configure soft delete
            builder.HasQueryFilter(o => !o.IsDeleted);
        }
    }
}
