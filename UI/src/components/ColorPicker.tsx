import { Check } from 'lucide-react';

const presetColors = [
  { name: 'Purple', value: '#8b5cf6' },
  { name: 'Blue', value: '#3b82f6' },
  { name: 'Cyan', value: '#06b6d4' },
  { name: 'Green', value: '#10b981' },
  { name: 'Lime', value: '#84cc16' },
  { name: 'Yellow', value: '#eab308' },
  { name: 'Orange', value: '#f59e0b' },
  { name: 'Red', value: '#ef4444' },
  { name: 'Pink', value: '#ec4899' },
  { name: 'Rose', value: '#f43f5e' },
  { name: 'Indigo', value: '#2b2eee' },
  { name: 'Violet', value: '#a855f7' },
  { name: 'Fuchsia', value: '#d946ef' },
  { name: 'Emerald', value: '#059669' },
  { name: 'Teal', value: '#14b8a6' },
  { name: 'Sky', value: '#0ea5e9' },
];

interface ColorPickerProps {
  selectedColor: string;
  onSelect: (color: string) => void;
}

export function ColorPicker({ selectedColor, onSelect }: ColorPickerProps) {
  return (
    <div className="space-y-3">
      <label className="block text-sm text-[#9aa3b2]">Accent Color</label>
      
      <div className="grid grid-cols-8 gap-2">
        {presetColors.map(color => {
          const isSelected = selectedColor.toLowerCase() === color.value.toLowerCase();
          
          return (
            <button
              key={color.value}
              type="button"
              onClick={() => onSelect(color.value)}
              className={`aspect-square rounded-xl transition-all hover:scale-110 active:scale-95 ${
                isSelected ? 'ring-2 ring-white ring-offset-2 ring-offset-[#0b1220] scale-110' : ''
              }`}
              style={{ backgroundColor: color.value }}
              aria-label={color.name}
            >
              {isSelected && (
                <div className="w-full h-full flex items-center justify-center">
                  <Check className="w-5 h-5 text-white drop-shadow-lg" strokeWidth={3} />
                </div>
              )}
            </button>
          );
        })}
      </div>

      {/* Custom color input */}
      <div className="flex items-center gap-3 pt-2">
        <label className="text-xs text-[#9aa3b2]">Custom:</label>
        <input
          type="color"
          value={selectedColor}
          onChange={(e) => onSelect(e.target.value)}
          className="w-12 h-12 rounded-xl cursor-pointer bg-transparent"
          style={{ 
            border: '2px solid #ffffff20',
          }}
        />
        <input
          type="text"
          value={selectedColor}
          onChange={(e) => {
            const value = e.target.value;
            if (/^#[0-9A-Fa-f]{0,6}$/.test(value)) {
              onSelect(value);
            }
          }}
          className="flex-1 px-3 py-2 bg-white/5 border border-white/10 rounded-xl text-sm focus:outline-none focus:border-white/20 transition-colors"
          placeholder="#000000"
        />
      </div>
    </div>
  );
}
