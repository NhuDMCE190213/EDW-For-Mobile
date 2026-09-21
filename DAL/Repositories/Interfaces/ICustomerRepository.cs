using DAL.Models;

namespace DAL.Repositories.Interfaces
{
    public interface ICustomerRepository
    {
        Task<List<Customer>> GetAllAsync();
        Task<Customer?> GetByIdAsync(int customerId);
        Task<Customer?> GetByEmailAsync(string email);
        Task<Customer> CreateAsync(Customer customer);
        Task<bool> UpdateAsync(Customer customer);
        Task<bool> DeleteAsync(int customerId);
        Task<bool> SetPasswordAsync(int customerId, string passwordHash);
    }
}