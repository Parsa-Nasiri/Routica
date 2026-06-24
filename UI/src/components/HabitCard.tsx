import { useState } from 'react';
import { Edit2, Trash2, MoreHorizontal, GripVertical } from 'lucide-react';
import { PixelHeatmap } from './PixelHeatmap';
import { getIconComponent } from './IconPicker';
import { Habit } from '../App';

interface HabitCardProps {
  habit: Habit;
  onToggle: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onUpdateDay: (habitId: string, date: string, status: 'completed' | 'skipped' | 'none', note?: string) => void;
  onDragStart: (habitId: string) => void;
  onDragOver: (e: React.DragEvent, habitId: string) => void;
  onDragEnd: () => void;
}

export function HabitCard({ 
  habit, 
  onToggle, 
  onEdit, 
  onDelete, 
  onUpdateDay,
  onDragStart,
  onDragOver,
  onDragEnd
}: HabitCardProps) {
  const [showActions, setShowActions] = useState(false);
  const [touchStart, setTouchStart] = useState<{ x: number; time: number } | null>(null);

  const Icon = getIconComponent(habit.iconId);
  const today = new Date().toISOString().split('T')[0];
  const isCompletedToday = habit.history[today]?.status === 'completed';

  // Calculate current streak
  const calculateStreak = () => {
    let streak = 0;
    const sortedDates = Object.keys(habit.history)
      .sort((a, b) => new Date(b).getTime() - new Date(a).getTime());
    
    for (const date of sortedDates) {
      if (habit.history[date].status === 'completed') {
        streak++;
      } else if (new Date(date) < new Date(today)) {
        break;
      }
    }
    
    return streak;
  };

  const currentStreak = calculateStreak();

  const handleTouchStart = (e: React.TouchEvent) => {
    setTouchStart({ x: e.touches[0].clientX, time: Date.now() });
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (!touchStart) return;
    
    const deltaX = e.touches[0].clientX - touchStart.x;
    if (Math.abs(deltaX) > 50) {
      setShowActions(true);
      setTouchStart(null);
    }
  };

  const handleTouchEnd = () => {
    if (touchStart && Date.now() - touchStart.time > 500) {
      // Long press detected
      setShowActions(true);
    }
    setTouchStart(null);
  };

  return (
    <div
      draggable
      onDragStart={() => onDragStart(habit.id)}
      onDragOver={(e) => onDragOver(e, habit.id)}
      onDragEnd={onDragEnd}
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
      className="group relative bg-[#1a2332] rounded-2xl p-5 shadow-xl border border-white/5 hover:border-white/10 transition-all hover:shadow-2xl cursor-move overflow-hidden"
    >
      {/* Drag Handle */}
      <div className="absolute left-2 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-40 transition-opacity">
        <GripVertical className="w-4 h-4 text-white" />
      </div>

      {/* Actions Menu */}
      {showActions && (
        <div className="absolute inset-0 bg-[#1a2332] rounded-2xl flex items-center justify-center gap-3 px-8 z-10 animate-in fade-in slide-in-from-right-5 duration-200">
          <button
            onClick={() => {
              onEdit();
              setShowActions(false);
            }}
            className="flex flex-col items-center gap-2 p-4 bg-blue-500/20 hover:bg-blue-500/30 rounded-2xl transition-all hover:scale-105 active:scale-95 min-w-[80px]"
            aria-label="Edit habit"
          >
            <Edit2 className="w-6 h-6 text-blue-400" />
            <span className="text-xs text-blue-400">Edit</span>
          </button>
          <button
            onClick={() => {
              onDelete();
              setShowActions(false);
            }}
            className="flex flex-col items-center gap-2 p-4 bg-red-500/20 hover:bg-red-500/30 rounded-2xl transition-all hover:scale-105 active:scale-95 min-w-[80px]"
            aria-label="Delete habit"
          >
            <Trash2 className="w-6 h-6 text-red-400" />
            <span className="text-xs text-red-400">Delete</span>
          </button>
          <button
            onClick={() => setShowActions(false)}
            className="flex flex-col items-center gap-2 p-4 bg-white/10 hover:bg-white/20 rounded-2xl transition-all hover:scale-105 active:scale-95 min-w-[80px]"
            aria-label="Close actions"
          >
            <MoreHorizontal className="w-6 h-6 text-white" />
            <span className="text-xs text-white">Close</span>
          </button>
        </div>
      )}

      {/* Header Section */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3 flex-1 min-w-0">
          <div 
            className="flex-shrink-0 w-12 h-12 rounded-xl flex items-center justify-center transition-transform group-hover:scale-105"
            style={{ backgroundColor: `${habit.color}20` }}
          >
            <Icon className="w-6 h-6" style={{ color: habit.color }} />
          </div>
          
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <h3 className="truncate">{habit.title}</h3>
              <button
                onClick={() => setShowActions(!showActions)}
                className="flex-shrink-0 p-1 rounded-lg bg-white/0 hover:bg-white/5 opacity-0 group-hover:opacity-100 transition-all"
                aria-label="Show actions"
              >
                <MoreHorizontal className="w-4 h-4 text-[#9aa3b2]" />
              </button>
            </div>
            <div className="flex items-center gap-2">
              <span 
                className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-xs"
                style={{ 
                  backgroundColor: `${habit.color}15`,
                  color: habit.color
                }}
              >
                {currentStreak > 0 && <span>🔥</span>}
                {currentStreak > 0 ? `${currentStreak} day${currentStreak !== 1 ? 's' : ''}` : 'No streak'}
              </span>
              <span className="text-xs text-[#9aa3b2]">
                {habit.frequencyGoal}/{habit.frequencyPeriod}
              </span>
            </div>
          </div>
        </div>

        {/* Check Button */}
        <button
          onClick={(e) => {
            e.stopPropagation();
            onToggle();
          }}
          className={`flex-shrink-0 w-11 h-11 rounded-xl border-2 flex items-center justify-center transition-all active:scale-95 ${
            isCompletedToday
              ? 'border-transparent scale-105'
              : 'border-white/20 hover:border-white/40'
          }`}
          style={{ 
            backgroundColor: isCompletedToday ? habit.color : 'transparent',
            boxShadow: isCompletedToday ? `0 0 20px ${habit.color}40` : 'none'
          }}
          aria-label={isCompletedToday ? 'Mark as incomplete' : 'Mark as complete'}
        >
          {isCompletedToday && (
            <svg 
              className="w-6 h-6 text-white animate-in zoom-in duration-200" 
              fill="none" 
              viewBox="0 0 24 24" 
              stroke="currentColor"
              strokeWidth={3}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
            </svg>
          )}
        </button>
      </div>

      {/* Description */}
      {habit.description && (
        <p className="text-[#9aa3b2] text-sm mb-4 line-clamp-2">{habit.description}</p>
      )}

      {/* Pixel Heatmap */}
      <PixelHeatmap 
        habit={habit} 
        onDayClick={(date, status) => onUpdateDay(habit.id, date, status)}
      />
    </div>
  );
}