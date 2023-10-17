#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>

void sendCommand(int fd, const char *command) {
    char fullCommand[128];
    snprintf(fullCommand, sizeof(fullCommand), "%s\r\n", command);
    write(fd, fullCommand, strlen(fullCommand));
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("请提供手机号码和短信内容作为参数\n");
        exit(1);
    }

    char *phoneNumber = argv[1];
    char *message = argv[2];

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

    sendCommand(fd, "AT+CMGF=0");

    char buffer[128];
    ssize_t n = read(fd, buffer, sizeof(buffer));
    // if (n > 0) {
    //     printf("返回值: %.*s\n", (int)n, buffer);
    // }
    usleep(10000);
    sendCommand(fd, "AT+CSCS=\"GSM\"");
    usleep(10000);
    n = read(fd, buffer, sizeof(buffer));
    // if (n > 0) {
    //     printf("返回值: %.*s\n", (int)n, buffer);
    // }

    char smsCommand[256];
    snprintf(smsCommand, sizeof(smsCommand), "AT+CMGS=%s", phoneNumber);
    sendCommand(fd, smsCommand);
    usleep(100000); 

    write(fd, message, strlen(message));
    // write(fd, "\r\n", 2);

    // 发送 Ctrl+Z 终止短信
    char ctrlZ = 0x1A;
    write(fd, &ctrlZ, 1);

    usleep(500000);

    n = read(fd, buffer, sizeof(buffer));
    if (n > 0) {
        printf("返回值: %.*s\n", (int)n, buffer);
    }

    close(fd);

    return 0;
}
