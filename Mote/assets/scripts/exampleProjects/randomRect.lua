--To understand this script, you should know that "#someList" means "The number of items in the table referred to by the someList variable"

SCREEN_WIDTH = 1026
SCREEN_HEIGHT = 768
MAX_RECTS = 512

rects = {}

function addRect()
    local rect = {}
    rect.x = math.random(0, SCREEN_WIDTH) - 128
    rect.y = math.random(0, SCREEN_HEIGHT) - 128
    rect.w = math.random(4, 512)
    rect.h = math.random(4, 512)
    
    rect.r = math.random(0, 255)
    rect.g = math.random(0, 255)
    rect.b = math.random(0, 255)
    rect.a = math.random(16, 255)
    
    rect.outlineOnly = math.random() > 0.65
        
    rects[#rects + 1] = rect
    
    --after MAX_RECTS rectangles are on the screen, when we add a new rectangle,
    --we remove the oldest rectangle that is likely no longer visible anyway
    --because newer rectangles are drawn over older rectangles.
    if #rects > MAX_RECTS then
        table.remove(rects, 1)
    end
end

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Random Rectangles")
end

function Update()
    addRect()
end

function Draw()
    ClearScreen(0, 0, 0)
    
    for i = 1, #rects do
        local r = rects[i]
        SetDrawColor(r.r, r.g, r.b, r.a)
        if r.outlineOnly then
            DrawRect(r.x, r.y, r.w, r.h)
        else
            FillRect(r.x, r.y, r.w, r.h)
        end
    end
end