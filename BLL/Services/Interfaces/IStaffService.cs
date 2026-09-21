using BLL.DTOs.Staff;

namespace BLL.Services.Interfaces
{
    public interface IStaffService
    {
        Task<StaffDto?> GetByEmailAsync(string email);
        Task<StaffDto?> ValidateLoginAsync(string email, string password);
        Task<StaffDto> CreateAsync(StaffCreateDto createDto);
        Task<bool> SetPasswordAsync(int staffId, string newPassword);
        Task<bool> UpdateProfileAsync(int staffId, StaffProfileDto profileDto);
        Task<StaffDashBoardDto?> GetStaffsListAsync(StaffDashBoardRequestDto requestDto);
        Task UpdateStaffAsync(int id, StaffUpdateDto staffUpdateDto);
        Task DeleteStaffAsync(int id);
    }
}