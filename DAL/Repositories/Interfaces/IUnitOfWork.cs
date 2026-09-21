using System;
using System.Threading.Tasks;

public interface IUnitOfWork : IAsyncDisposable
{
    IRepository<T> Repository<T>() where T : class;

    Task<int> SaveChangesAsync();

    Task BeginTransactionAsync();
    Task CommitAsync();
    Task RollbackAsync();
}