using DAL.Data;
using DAL.Models;
using DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace DAL.Repositories
{
    public class StaffRepository : IStaffRepository
    {
        private readonly AppDbContext _context;
        private readonly ILogger<StaffRepository> _logger;

        public StaffRepository(AppDbContext context, ILogger<StaffRepository> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<Staff>> GetAllAsync()
        {
            return await _context.Staffs.ToListAsync();
        }

        public async Task<Staff?> GetByIdAsync(int staffId)
        {
            return await _context.Staffs.FindAsync(staffId);
        }

        public async Task<Staff?> GetByEmailAsync(string email)
        {
            return await _context.Staffs.FirstOrDefaultAsync(s => s.Email == email);
        }

        public async Task<Staff> CreateAsync(Staff staff)
        {
            _context.Staffs.Add(staff);
            await _context.SaveChangesAsync();
            return staff;
        }

        public async Task<bool> UpdateAsync(Staff staff)
        {
            var existing = await _context.Staffs.FindAsync(staff.StaffId);
            if (existing != null)
            {
                existing.FullName = staff.FullName;
                existing.Email = staff.Email;
                existing.Role = staff.Role;
                existing.IsActive = staff.IsActive;
                existing.UpdatedAt = DateTime.UtcNow;

                _context.Entry(existing).Property(x => x.FullName).IsModified = true;
                _context.Entry(existing).Property(x => x.Email).IsModified = true;
                _context.Entry(existing).Property(x => x.Role).IsModified = true;
                _context.Entry(existing).Property(x => x.IsActive).IsModified = true;
                _context.Entry(existing).Property(x => x.UpdatedAt).IsModified = true;

                await _context.SaveChangesAsync();
                return true;
            }

            return false;
        }

        public async Task<bool> DeleteAsync(int staffId)
        {
            var staff = await _context.Staffs.FirstOrDefaultAsync(s => s.StaffId == staffId);
            if (staff != null)
            {
                staff.IsDeleted = true;
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }

        public async Task<bool> SetPasswordAsync(int staffId, string passwordHash)
        {
            var staff = await _context.Staffs.FindAsync(staffId);
            if (staff != null)
            {
                staff.PasswordHash = passwordHash;
                staff.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }
    }
}