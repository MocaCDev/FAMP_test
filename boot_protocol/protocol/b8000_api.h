#ifndef protocol_b8000_api
#define protocol_b8000_api

#ifdef __cplusplus
extern "C" {
#endif

#define rows        25
#define cols        80

/* Declare this in a header file somewhere. */
static uint16 *vid_mem = (uint16 *)0xB8000;

/* Color attributes for `print` */
enum color_attr
{
    black           = 0x00,
    blue            = 0x01,
    green           = 0x02,
    cyan            = 0x03,
    red             = 0x04,
    magenta         = 0x05,
    brown           = 0x06,
    light_grey      = 0x07,
    dark_grey       = 0x08,
    light_blue      = 0x09,
    lime_green      = 0x0A,
    light_cyan      = 0x0B,
    light_red       = 0x0C,
    light_magenta   = 0x0D,
    yellow          = 0x0E,
    white           = 0x0F,
    wwhite          = 0xF0,
    rred            = 0xF4,
    cyan_white      = 0x3F,
    cyan_red        = 0x34,
};

typedef struct cursor_info
{
    uint32      pos_x;
    uint32      pos_y;
} _cursor_info;

static _cursor_info c_info = {.pos_x = 0, .pos_y = 0};

/*
 *  __inp: back-end function
 *
 *  Read-in a value from a port
 *
 *  Input: uint16 port
 *  Output: uint8 rv(return-value from the port)
 *  On Error: This function does not error
 */
uint8 __inp(uint16 port) {
    uint8 rv;
    
    __asm__ __volatile__("in %0, %1": "=a"(rv): "dN"(port));
    return rv;
}
/*
 *  __outp: back-end function
 *
 *  Write a value to a port
 *
 *  Input: uint16 port, uint8 data
 *  Output: None
 *  On Error: This function does not error
 */
void __outp(uint16 port, uint8 data) {
    __asm__ __volatile__("outb %0, %1":: "dN"(port), "a"(data));
}

#define reg_screen_ctr  0x3D4
#define reg_screen_data 0x3D5

/* Last cursor X position after enter is pressed. */
static uint16 last_cursor_x = 0;

void update_cursor_pos()
{
    uint16 pos = (c_info.pos_y * 80) + c_info.pos_x;
    __outp(reg_screen_ctr, 14);
    __outp(reg_screen_data, pos >> 8);
    __outp(reg_screen_ctr, 15);
    __outp(reg_screen_data, pos & 0xFF);
}

void init_cursor_pos()
{
    /* Set `pos_x`/`pos_y` to zero to initialize. */
    c_info.pos_x = c_info.pos_y = 0;

    update_cursor_pos();
}

void put_char(uint8 character)
{
    switch(character)
    {
        case '\n':
        {
            c_info.pos_y++;
            last_cursor_x = c_info.pos_x;
            c_info.pos_x = 0;
            goto end;
        }
        case '\t':
        {
            c_info.pos_x+=4;
            goto end;
        }
        case 0x0E:
        {
            if(c_info.pos_x >= 1)
            {
                c_info.pos_x--;
                vid_mem[c_info.pos_x + (c_info.pos_y * 80)] = (cyan_white << 8) | (0xFF & ' ');
                goto end;
            }

            if(c_info.pos_x == 0 && c_info.pos_y > 0)
            {
                c_info.pos_y--;
                c_info.pos_x = last_cursor_x;
                goto end;
            }
            return;
        }
        /* Do nothing if the above does not run. */
        default: break;
    }

    vid_mem[c_info.pos_x + (c_info.pos_y * 80)] =  (cyan_white << 8) | (0xFF & character);
    c_info.pos_x++;

    end:
    update_cursor_pos();
}

void print(const uint8 *str)
{
    lsize i = 0;
    uint8 color = cyan_white;

    while(str[i] != '\0')
    {
        /* Check the current character to see if it is any of the given
         * "special" characters.
         */
        redo:
        switch(str[i])
        {
            case '\n':
            {
                c_info.pos_y++;
                c_info.pos_x = 0;
                i++;
                goto redo;
            }
            case '\t':c_info.pos_x += 4;i++;goto redo;
            case '@':
            {
                i++;
                
                switch(str[i])
                {
                    case 'b':
                    {
                        if(str[i+1] == 'r')
                        {
                            i++;
                            color = brown;
                        }
                        else color = blue;
                        i++;
                        goto redo;
                    }
                    case 'B':
                    {
                        color = black;
                        i++;
                        goto redo;
                    }
                    case 'r':
                    {
                        if(str[i+1] == 'e')
                        {
                            i++;
                            color = cyan_white;
                        }
                        else color = cyan_red;
                        i++;
                        goto redo;
                    }
                    case 'c':
                    {
                        color = cyan;
                        i++;
                        goto redo;
                    }
                    case 'm':
                    {
                        color = magenta;
                        i++;
                        goto redo;
                    }
                    case 'g':
                    {
                        color = green;
                        i++;
                        goto redo;
                    }
                    default: i++;goto redo;
                }
            }
            case '\0':goto end;
            default: break;
        }

        /* Write character to according index in the video memory buffer. */
        vid_mem[c_info.pos_x + (c_info.pos_y * 80)] = (color << 8) | (0xFF & str[i]);

        /* Increment index/cursor x position. */
        i++;
        c_info.pos_x++;

        /* Check if the x position surpasses or is directly equal to
         * the width of the screen. If it is, add newline.
         */
        if(c_info.pos_x >= 80)
        {
            c_info.pos_x = 0;
            c_info.pos_y++;
        }
    }

    end:
    return;
}

uint16 *memset(uint16 *dest, uint16 val, lsize count){
	uint16* dstPtr = (uint16 *)dest;

    for (; count != 0; count--) *dstPtr++ = val;
	
	return dest;
}

uint16 get_text_attribute(uint8 foreground, uint8 background)
{
    return (foreground << 4) | (background & 0x0F);
}

uint16 get_text_value(uint8 character, uint8 foreground, uint8 background){
	return character | (get_text_attribute(foreground, background) << 8);
}

void clear_screen(uint8 color)
{
    uint16 i = 0;
    while(i < rows*cols)
    {
        memset((uint16 *)0xB8000 + (i * cols), get_text_value(' ', cyan, white), cols);
        i++;
    }
    //vid_mem = (uint16 *) 0xB8000;
}

#ifdef __cplusplus
}
#endif

#endif