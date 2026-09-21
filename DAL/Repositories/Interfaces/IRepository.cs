using System.Linq;
using System.Threading.Tasks;

public interface IRepository<T> where T : class
{
    IQueryable<T> Query();

    Task AddAsync(T entity);
    Task RemoveAsync(T entity);
}