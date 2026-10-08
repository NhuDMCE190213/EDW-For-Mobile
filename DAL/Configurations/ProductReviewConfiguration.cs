using DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace DAL.Configurations
{
    public class ProductReviewConfiguration : IEntityTypeConfiguration<ProductReview>
    {
        public void Configure(EntityTypeBuilder<ProductReview> builder)
        {
            builder.ToTable("product_reviews");
            builder.HasKey(pr => pr.Id);
            builder.Property(pr => pr.Rating).IsRequired();
            builder.Property(pr => pr.Comment).HasMaxLength(1000);

            builder.HasOne(pr => pr.Customer)
                   .WithMany()
                   .HasForeignKey(pr => pr.CustomerId)
                   .HasConstraintName("fk_product_reviews_customers_customer_id")
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(pr => pr.Product)
                   .WithMany()
                   .HasForeignKey(pr => pr.ProductId)
                   .HasConstraintName("fk_product_reviews_products_product_id")
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasQueryFilter(pr => !pr.IsDeleted);
        }
    }
}