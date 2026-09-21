using DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace DAL.Configurations
{
    public class CustomerConfiguration : IEntityTypeConfiguration<Customer>
    {
        public void Configure(EntityTypeBuilder<Customer> builder)
        {
            builder.HasKey(c => c.CustomerId);
            builder.Property(c => c.FullName).IsRequired().HasMaxLength(100);
            builder.Property(c => c.Email).IsRequired().HasMaxLength(255);
            builder.HasIndex(c => c.Email).IsUnique();
            builder.Property(c => c.PhoneNumber).HasMaxLength(20);
            builder.Property(c => c.PasswordHash).IsRequired();
            builder.Property(c => c.Role).IsRequired();
            builder.Property(c => c.Points).IsRequired();

            builder.HasQueryFilter(c => !c.IsDeleted);
        }
    }
}