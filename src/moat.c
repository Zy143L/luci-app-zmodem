#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("请提供要发送的 AT 命令\n");
        exit(1);
    }

    int fd = open("/dev/ttyUSB3", O_RDWR);
    if (fd == -1) {
        perror("无法打开串口设备");
        exit(1);
    }

    struct termios options;
    tcgetattr(fd, &options);
    cfsetispeed(&options, B115200);
    cfsetospeed(&options, B115200);
    options.c_cflag |= (CLOCAL | CREAD);
    options.c_cflag &= ~PARENB;
    options.c_cflag &= ~CSTOPB;
    options.c_cflag &= ~CSIZE;
    options.c_cflag |= CS8;
    options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
    options.c_oflag &= ~OPOST;
    tcsetattr(fd, TCSANOW, &options);

    char *command = argv[1];
    size_t command_len = strlen(command);
    char *full_command = malloc(command_len + 3);
    strcpy(full_command, command);
    strcat(full_command, "\r\n");
    write(fd, full_command, strlen(full_command));

    usleep(100000);

    char buffer[4096];
    ssize_t n = read(fd, buffer, sizeof(buffer));
    if (n > 0) {
        printf("%.*s", (int)n, buffer);
    }

    close(fd);

    free(full_command);

    return 0;
}
