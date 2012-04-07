[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Posix
{
    [CCode (cheader_filename = "unistd.h")]
    public int daemon (int nochdir, int noclose);

    [CCode (cheader_filename = "asm/ioctls.h")]
    public const int TIOCNOTTY;

    [CCode (cheader_filename = "linux/kd.h")]
    public const int KDSETMODE;

    [CCode (cheader_filename = "linux/kd.h")]
    public const int KDSKBMODE;

    [CCode (cheader_filename = "linux/kd.h")]
    public const int KD_GRAPHICS;

    [CCode (cheader_filename = "linux/kd.h")]
    public const int K_RAW;

    [CCode (cheader_filename = "linux/kd.h")]
    public const int KDGKBMODE;

    [CCode (cheader_filename = "linux/vt.h")]
    public const int VT_ACTIVATE;

    [CCode (cheader_filename = "linux/vt.h")]
    public const int VT_WAITACTIVE;

    [SimpleType]
    [CCode (cheader_filename = "setjmp.h")]
    public struct jmp_buf
    {
    }

    [CCode (cheader_filename = "setjmp.h")]
    public int setjmp(jmp_buf env);

    [CCode (cheader_filename = "setjmp.h")]
    public void longjmp(jmp_buf env, int val);

    [CCode (cheader_filename = "sys/ipc.h,sys/shm.h")]
    public int shmget(key_t key, size_t size, int shmflg);

    [CCode (cheader_filename = "sys/ipc.h,sys/sem.h")]
    public int semget(key_t key, int nsems, int semflg);

    [CCode (cheader_filename = "sys/types.h,sys/shm.h")]
    public void *shmat(int shmid, void *shmaddr, int shmflg);

    [CCode (cheader_filename = "sys/types.h,sys/shm.h")]
    public int shmdt(void *shmaddr);

    [CCode (cheader_filename = "sys/types.h,sys/ipc.h,sys/sem.h", cname = "struct sembuf")]
    public struct Sembuf
    {
        public ushort sem_num;
        public short sem_op;
        public short sem_flg;
    }

    [CCode (cheader_filename = "sys/types.h,sys/ipc.h,sys/sem.h")]
    public int semop(int semid, ref Sembuf sops, uint nsops);

    [CCode (cheader_filename = "sys/ipc.h")]
    public const int IPC_CREAT;

    [CCode (cheader_filename = "sys/ipc.h")]
    public const int IPC_EXCL;

    [CCode (cheader_filename = "sys/ipc.h")]
    public const int IPC_NOWAIT;

    [CCode (cheader_filename = "sys/ipc.h")]
    public const short SEM_UNDO;
}