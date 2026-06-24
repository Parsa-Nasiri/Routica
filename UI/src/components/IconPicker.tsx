import { 
  Brain, Dumbbell, Book, Droplet, Code, Heart, Coffee, Music, 
  Bike, Camera, Palette, Flame, Moon, Sun, Zap, Target,
  Pencil, Smile, Star, TrendingUp, Award, Clock, CheckCircle,
  Activity, Briefcase, Gift, Home, Leaf, Mountain, Sparkles,
  Users, Wind, Apple, Cookie, Pizza, Sandwich, Salad, Soup,
  type LucideIcon
} from 'lucide-react';

const iconMap: Record<string, LucideIcon> = {
  brain: Brain,
  dumbbell: Dumbbell,
  book: Book,
  droplet: Droplet,
  code: Code,
  heart: Heart,
  coffee: Coffee,
  music: Music,
  bike: Bike,
  camera: Camera,
  palette: Palette,
  flame: Flame,
  moon: Moon,
  sun: Sun,
  zap: Zap,
  target: Target,
  pencil: Pencil,
  smile: Smile,
  star: Star,
  trending: TrendingUp,
  award: Award,
  clock: Clock,
  check: CheckCircle,
  activity: Activity,
  briefcase: Briefcase,
  gift: Gift,
  home: Home,
  leaf: Leaf,
  mountain: Mountain,
  sparkles: Sparkles,
  users: Users,
  wind: Wind,
  apple: Apple,
  cookie: Cookie,
  pizza: Pizza,
  sandwich: Sandwich,
  salad: Salad,
  soup: Soup,
};

export const getIconComponent = (iconId: string): LucideIcon => {
  return iconMap[iconId] || Brain;
};

interface IconPickerProps {
  selectedIcon: string;
  onSelect: (iconId: string) => void;
  color: string;
}

export function IconPicker({ selectedIcon, onSelect, color }: IconPickerProps) {
  const icons = Object.keys(iconMap);
  
  return (
    <div className="space-y-3">
      <label className="block text-sm text-[#9aa3b2]">Icon</label>
      
      <div className="grid grid-cols-8 gap-2">
        {icons.map(iconId => {
          const Icon = iconMap[iconId];
          const isSelected = selectedIcon === iconId;
          
          return (
            <button
              key={iconId}
              type="button"
              onClick={() => onSelect(iconId)}
              className={`aspect-square rounded-xl flex items-center justify-center transition-all hover:scale-105 active:scale-95 ${
                isSelected ? 'ring-2' : 'hover:bg-white/5'
              }`}
              style={{
                backgroundColor: isSelected ? `${color}20` : '#ffffff05',
                ringColor: isSelected ? color : 'transparent'
              }}
              aria-label={iconId}
            >
              <Icon 
                className="w-5 h-5" 
                style={{ color: isSelected ? color : '#9aa3b2' }}
              />
            </button>
          );
        })}
      </div>
      
      <p className="text-xs text-[#9aa3b2]">
        {icons.length} icons available
      </p>
    </div>
  );
}
