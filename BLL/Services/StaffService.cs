using AutoMapper;
using BLL.DTOs.Pagination;
using BLL.DTOs.Staff;
using BLL.Services.Interfaces;
using DAL.Models;
using DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BLL.Services
{
    public class StaffService : IStaffService
    {
        /*
         StaffService (BLL)
         - Handles staff-related operations used by Admin.Blazor and UserStaff.Razor
         - Methods: GetByEmailAsync, ValidateLoginAsync (BCrypt.Verify), CreateAsync (hashes),
             and SetPasswordAsync (hash+update)
         - Delegates data access to IStaffRepository
        */
        private readonly IStaffRepository _staffRepository;
        private readonly ILogger<StaffService> _logger;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IMapper _mapper;

        public StaffService(IStaffRepository staffRepository, ILogger<StaffService> logger, IUnitOfWork unitOfWork, IMapper mapper)
        {
            _staffRepository = staffRepository;
            _logger = logger;
            _unitOfWork = unitOfWork;
            _mapper = mapper;
        }

        public async Task<StaffDto?> GetByEmailAsync(string email)
        {
            var staff = await _staffRepository.GetByEmailAsync(email);
            if (staff == null) return null;

            return new StaffDto
            {
                StaffId = staff.StaffId,
                FullName = staff.FullName,
                Email = staff.Email,
                Role = staff.Role,
                IsActive = staff.IsActive,
                CreatedAt = staff.CreatedAt,
                UpdatedAt = staff.UpdatedAt
            };
        }

        public async Task<StaffDto?> ValidateLoginAsync(string email, string password)
        {
            var staff = await _staffRepository.GetByEmailAsync(email);
            if (staff == null) return null;

            var verified = BCrypt.Net.BCrypt.Verify(password, staff.PasswordHash);
            if (!verified) return null;

            if (!staff.IsActive || staff.IsDeleted) return null;

            return new StaffDto
            {
                StaffId = staff.StaffId,
                FullName = staff.FullName,
                Email = staff.Email,
                Role = staff.Role,
                IsActive = staff.IsActive,
                CreatedAt = staff.CreatedAt,
                UpdatedAt = staff.UpdatedAt
            };
        }

        public async Task<StaffDto> CreateAsync(StaffCreateDto createDto)
        {
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(createDto.Password);
            var staff = new Staff
            {
                FullName = createDto.FullName,
                Email = createDto.Email,
                PasswordHash = passwordHash,
                Role = createDto.Role,
                IsActive = createDto.IsActive,
                IsDeleted = false,
                CreatedAt = DateTime.UtcNow
            };
            var created = await _staffRepository.CreateAsync(staff);

            return new StaffDto
            {
                StaffId = created.StaffId,
                FullName = created.FullName,
                Email = created.Email,
                Role = created.Role,
                IsActive = created.IsActive,
                CreatedAt = created.CreatedAt,
                UpdatedAt = created.UpdatedAt
            };
        }

        public async Task<bool> SetPasswordAsync(int staffId, string newPassword)
        {
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            return await _staffRepository.SetPasswordAsync(staffId, passwordHash);
        }

        public async Task<bool> UpdateProfileAsync(int staffId, StaffProfileDto profileDto)
        {
            var staff = await _staffRepository.GetByIdAsync(staffId);
            if (staff == null) return false;

            staff.FullName = profileDto.FullName;
            staff.UpdatedAt = DateTime.UtcNow;

            return await _staffRepository.UpdateAsync(staff);
        }

        public async Task<StaffDashBoardDto?> GetStaffsListAsync(StaffDashBoardRequestDto requestDto)
        {
            var staffQuery = _unitOfWork.Repository<Staff>().Query().IgnoreQueryFilters();

            if (!string.IsNullOrEmpty(requestDto.SearchTerm))
                staffQuery = staffQuery.Where(s => s.FullName.ToLower().Contains(requestDto.SearchTerm!.ToLower()));

            if (!requestDto.IncludeDisable) staffQuery = staffQuery.Where(s => s.IsActive);
            if (!requestDto.IncludeDelete) staffQuery = staffQuery.Where(s => !s.IsDeleted);

            var totalCount = await staffQuery.CountAsync();
            var activeCount = await staffQuery.CountAsync(s => s.IsActive && !s.IsDeleted);

            var staffList = await staffQuery
                .Skip((requestDto.Pagination.Page - 1) * requestDto.Pagination.PageSize)
                .Take(requestDto.Pagination.PageSize)
                .ToListAsync();

            return new StaffDashBoardDto
            {
                ActiveCount = activeCount,
                Pagination = new PaginatedResponse<StaffDto>
                {
                    Items = _mapper.Map<List<StaffDto>>(staffList),
                    Page = requestDto.Pagination.Page,
                    PageSize = requestDto.Pagination.PageSize,
                    TotalCount = totalCount
                }
            };
        }

        public async Task UpdateStaffAsync(int id, StaffUpdateDto staffUpdateDto)
        {
            try
            {
                await _unitOfWork.BeginTransactionAsync();
                var staff = await _unitOfWork.Repository<Staff>().Query().FirstOrDefaultAsync(s => s.StaffId == id);
                if (staff is null)
                {
                    throw new Exception("Staff Not Found!");
                }
                staff.Update(staffUpdateDto.Email, staffUpdateDto.FullName, staffUpdateDto.Role, staffUpdateDto.IsActive);
                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitAsync();
            }
            catch (Exception ex)
            {
                await _unitOfWork.RollbackAsync();
                throw new Exception(ex.Message);
            }
        }

        public async Task DeleteStaffAsync(int id)
        {
            try
            {
                await _unitOfWork.BeginTransactionAsync();
                var staff = await _unitOfWork.Repository<Staff>().Query().FirstOrDefaultAsync(s => s.StaffId == id);
                if (staff is null)
                {
                    throw new Exception($"Staff Not Found!");
                }
                staff.IsDeleted = true;
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