using DAL.Models;

namespace DAL.Repositories.Interfaces
{
    public interface IStaffRepository
    {
        Task<List<Staff>> GetAllAsync();
        Task<Staff?> GetByIdAsync(int staffId);
        Task<Staff?> GetByEmailAsync(string email);
        Task<Staff> CreateAsync(Staff staff);
        Task<bool> UpdateAsync(Staff staff);
        Task<bool> DeleteAsync(int staffId);
        Task<bool> SetPasswordAsync(int staffId, string passwordHash);
    }
}