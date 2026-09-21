using AutoMapper;
using BLL.DTOs.Customer;
using BLL.DTOs.Pagination;
using BLL.DTOs.Staff;
using BLL.Services.Interfaces;
using DAL.Enums;
using DAL.Models;
using DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BLL.Services
{
    public class CustomerService : ICustomerService
    {
        /*
         CustomerService (BLL)
         - Provides high-level operations for customer entities used by MVC/UI layers
         - Responsibilities: lookup by email, validate login (BCrypt.Verify), create user
             (hashes password with BCrypt), and set password (hash+update)
         - This layer calls repository interfaces (ICustomerRepository) to access DB
        */
        private readonly ICustomerRepository _customerRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IMapper _mapper;

        public CustomerService(ICustomerRepository customerRepository, IUnitOfWork unitOfWork, IMapper mapper)
        {
            _customerRepository = customerRepository;
            _unitOfWork = unitOfWork;
            _mapper = mapper;
        }

        public async Task<CustomerDto?> GetByEmailAsync(string email)
        {
            // Return DTO or null if not found. Used by forgot-password flows.
            var customer = await _customerRepository.GetByEmailAsync(email);
            if (customer == null) return null;

            return new CustomerDto
            {
                CustomerId = customer.CustomerId,
                FullName = customer.FullName,
                Email = customer.Email,
                PhoneNumber = customer.PhoneNumber,
                Role = customer.Role,
                Points = customer.Points,
                CreatedAt = customer.CreatedAt,
                UpdatedAt = customer.UpdatedAt
            };
        }

        public async Task<CustomerDto?> ValidateLoginAsync(string email, string password)
        {
            // Validate credentials: fetch entity and verify hashed password using BCrypt
            var customer = await _customerRepository.GetByEmailAsync(email);
            if (customer == null) return null;

            var verified = BCrypt.Net.BCrypt.Verify(password, customer.PasswordHash);
            if (!verified) return null;

            if (!customer.IsActive || customer.IsDeleted) return null;

            return new CustomerDto
            {
                CustomerId = customer.CustomerId,
                FullName = customer.FullName,
                Email = customer.Email,
                PhoneNumber = customer.PhoneNumber,
                Role = customer.Role,
                Points = customer.Points,
                CreatedAt = customer.CreatedAt,
                UpdatedAt = customer.UpdatedAt
            };
        }

        public async Task<CustomerDto> CreateAsync(CustomerCreateDto createDto)
        {
            // Create a new customer: hash password then persist via repository
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(createDto.Password);
            var customer = new Customer
            {
                FullName = createDto.FullName,
                Email = createDto.Email,
                PhoneNumber = createDto.PhoneNumber,
                PasswordHash = passwordHash,
                Role = (RoleEnum)createDto.Role,
                Points = createDto.Points,
                IsDeleted = false,
                CreatedAt = DateTime.UtcNow
            };
            var created = await _customerRepository.CreateAsync(customer);

            return new CustomerDto
            {
                CustomerId = created.CustomerId,
                FullName = created.FullName,
                Email = created.Email,
                PhoneNumber = created.PhoneNumber,
                Role = created.Role,
                Points = created.Points,
                CreatedAt = created.CreatedAt,
                UpdatedAt = created.UpdatedAt
            };
        }

        public async Task<bool> SetPasswordAsync(int customerId, string newPassword)
        {
            // Hash the provided new password and delegate update to repository
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            return await _customerRepository.SetPasswordAsync(customerId, passwordHash);
        }

        public async Task<bool> UpdateProfileAsync(int customerId, CustomerProfileDto profileDto)
        {
            var customer = await _customerRepository.GetByIdAsync(customerId);
            if (customer == null) return false;

            customer.FullName = profileDto.FullName;
            customer.PhoneNumber = profileDto.PhoneNumber;
            customer.UpdatedAt = DateTime.UtcNow;

            return await _customerRepository.UpdateAsync(customer);
        }

        public async Task<CustomerDashBoardDto> GetCustomersAsync(CustomerDashBoardRequestDto requestDto)
        {
            var query = _unitOfWork.Repository<Customer>().Query().IgnoreQueryFilters().AsNoTracking();

            if (!string.IsNullOrEmpty(requestDto.SearchTerm))
                query = query.Where(c => c.FullName.ToLower().Contains(requestDto.SearchTerm.ToLower()));

            if (!requestDto.IncludeDelete)
                query = query.Where(c => !c.IsDeleted);

            if (!requestDto.IncludeDisable)
                query = query.Where(c => c.IsActive);

            var totalCount = await query.CountAsync();
            var activeCount = await query.CountAsync(c => c.IsActive && !c.IsDeleted);

            var pagedItems = await query
                .Skip((requestDto.Pagination.Page - 1) * requestDto.Pagination.PageSize)
                .Take(requestDto.Pagination.PageSize)
                .ToListAsync();

            var items = _mapper.Map<List<CustomerDto>>(pagedItems);

            var page = new PaginatedResponse<CustomerDto>
            {
                Items = items,
                Page = requestDto.Pagination.Page,
                PageSize = requestDto.Pagination.PageSize,
                TotalCount = totalCount     
            };

            return new CustomerDashBoardDto
            {
                ActiveCount = activeCount,     
                Pagination = page
            };

            
        }

        public async Task UpdateCustomerAsync(int customerId, CustomerUpdateDto customerUpdateDto)
        {
            try
            {
                await _unitOfWork.BeginTransactionAsync();
                var customer = await _unitOfWork.Repository<Customer>().Query().FirstOrDefaultAsync(c => c.CustomerId == customerId);
                if (customer is null) throw new Exception("Customer not found!");
                customer.Update(customerUpdateDto.FullName, customerUpdateDto.Email, customerUpdateDto.PhoneNumber, customerUpdateDto.Role, customerUpdateDto.Points, customerUpdateDto.IsActive);
                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitAsync();

            }
            catch (Exception ex)
            {
                await _unitOfWork.RollbackAsync();
                throw new Exception(ex.Message);
            }
        }

        public async Task DeleteCustomerAsync(int customerId)
        {
            try
            {
                await _unitOfWork.BeginTransactionAsync();
                var customer = await _unitOfWork.Repository<Customer>().Query().FirstOrDefaultAsync(c => c.CustomerId == customerId);
                if (customer is null) throw new Exception("Customer not found!");
                customer.Delete(true);
                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitAsync();
            }
            catch (Exception ex)
            {
                await _unitOfWork.RollbackAsync();
                throw new Exception(ex.Message);
            }
        }
    }
}