using Microsoft.VisualBasic;

namespace DAL.Models.Base
{
    public interface IBaseEntity
    {
        bool IsDeleted { get; set; }

        DateTime CreatedAt { get; set; }
        DateTime? UpdatedAt { get; set; }
    }
}
