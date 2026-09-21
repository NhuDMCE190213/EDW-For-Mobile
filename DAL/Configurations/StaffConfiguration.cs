using DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace DAL.Configurations
{
    public class StaffConfiguration : IEntityTypeConfiguration<Staff>
    {
        public void Configure(EntityTypeBuilder<Staff> builder)
        {
            builder.ToTable("staffs");

            builder.HasKey(s => s.StaffId);
            builder.Property(s => s.Email).IsRequired().HasMaxLength(255);
            builder.Property(s => s.FullName).IsRequired().HasMaxLength(100);
            builder.Property(s => s.PasswordHash).IsRequired();
            builder.Property(s => s.Role).IsRequired();
            builder.Property(s => s.IsActive).IsRequired();

            builder.HasIndex(s => s.Email).IsUnique();
            builder.HasQueryFilter(s => !s.IsDeleted);
        }
    }
}