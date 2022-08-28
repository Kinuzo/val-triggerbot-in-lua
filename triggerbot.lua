_G.obs = obslua
_G.bit = require("bit")
_G.ffi = require("ffi")
_G.captura = 0
_G.posicao = 0
_G.altura = 0
_G.distancia = -96
_G.click = false
_G.bindzinha = 2
_G.lista = {{"M4", 5}, {"M5", 6}}

ffi.cdef [[
typedef int (__stdcall *WNDENUMPROC)(void *hwnd);
int EnumWindows(WNDENUMPROC address, intptr_t params);
int GetClientRect(void *hwnd, int *buffer);
int __stdcall GetWindowTextA( void *hWnd, char *lpString, int nMaxCount);
intptr_t strstr(char* _String, const char * _SubString);
int __stdcall SetWindowLongPtrA(void *hwnd, int nIndex, long long dwNewLong);
void *GetDC(void *window_handle);
unsigned short GetAsyncKeyState(int vKey);
unsigned int GetPixel(void *window, int x, int y);
int __stdcall PostMessageA(void *hWnd, int Msg, intptr_t wParam, intptr_t lParam);
void *__stdcall GetForegroundWindow();
]]

function script_properties() -- Tecla
    local binds = obs.obs_properties_create()
    local ativar =
        obs.obs_properties_add_list(
        binds,
        "bindzinha", "Bind",
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING
    )

    for i = 1, #lista do
        obs.obs_property_list_add_string(ativar, lista[i][1], lista[i][1])
    end

    return binds
end

local function pegar_key(name)
    for i = 1, #lista do
        if lista[i][1] == name then
            return lista[i][2]
        end
    end
    return 0
end

function initialize_window() -- Captura de tela
    if captura ~= 0 then
        return 1
    end

    local obs_handle = 0

    ffi.C.EnumWindows(
        function(hwnd)
            local obspracurtir = ffi.new("char[260]", 0)
            ffi.C.GetWindowTextA(hwnd, obspracurtir, 260)

            if ffi.C.strstr(obspracurtir, "OBS ") > 0 then
                obs_handle = hwnd
                return false
            end
            return true
        end,
        0
    )

    if obs_handle == 0 then
        return 0
    end

    ffi.C.SetWindowLongPtrA(obs_handle, -16, 0x14cc0000)
    captura = ffi.C.GetDC(obs_handle)

    local reta = ffi.new("int[4]", 0)
    ffi.C.GetClientRect(obs_handle, reta)

    posicao = (reta[2] - reta[0]) / 2
    altura = (reta[3] - reta[1]) / 2

    return 1
end

function script_update(config)
    bindzinha = pegar_key(obs.obs_data_get_string(config, "bindzinha"))
end

local function cor(red, green, blue) -- Cor que ele vai puxar
    if green >= 43 then
       return math.abs(red - blue) <= 8 and red - green >= 17 and blue - green >= 22 and red >= 78 and blue >= 87;
    end
 end

local function Vermelhao(c) return
    bit.band(c, 0xff)
end

local function Verdao(c) return
    bit.band(bit.rshift(c, 8), 0xff)
end

local function Azulzao(c) return
    bit.band(bit.rshift(c, 16), 0xff)
end

function script_tick(seconds)
    if initialize_window() and ffi.C.GetAsyncKeyState(bindzinha) > 0 then
        local achou = false

        for y = -3, 4, 1 do
            for x = -1, 2, 1 do
                local pixelzin = ffi.C.GetPixel(captura, posicao + x, altura + y + distancia)
                if cor(Vermelhao(pixelzin), Verdao(pixelzin), Azulzao(pixelzin)) then -- Ele vai procurar a combinação de cores e caso encontre ele vai prosseguir
                    achou = true
                    goto continue
                end
            end
        end

        ::continue::

        if achou then  -- Ele vai atirar caso tenha confirmado que encontrou a combinação de cores
            if click == false then
                ffi.C.PostMessageA(ffi.C.GetForegroundWindow(), 0x100, 1, 0)
                click = true
            end
        else
            if click == true then
                ffi.C.PostMessageA(ffi.C.GetForegroundWindow(), 0x101, 1, 0)
                click = false
            end
        end
    else
        if click == true then
            ffi.C.PostMessageA(ffi.C.GetForegroundWindow(), 0x101, 1, 0)
            click = false
        end
    end
end
