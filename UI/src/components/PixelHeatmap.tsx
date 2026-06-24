import { useState } from 'react';
import { X } from 'lucide-react';
import { Habit } from '../App';

interface PixelHeatmapProps {
  habit: Habit;
  onDayClick?: (date: string, status: 'completed' | 'skipped' | 'none') => void;
}

export function PixelHeatmap({ habit, onDayClick }: PixelHeatmapProps) {
  const [selectedDay, setSelectedDay] = useState<{ date: string; x: number; y: number } | null>(null);
  
  const daysToShow = 56; // 8 weeks
  const pixelsPerRow = 14;
  const rows = Math.ceil(daysToShow / pixelsPerRow);

  const getDayData = () => {
    const days: Array<{ date: string; status: 'completed' | 'skipped' | 'none' }> = [];
    const today = new Date();
    
    for (let i = daysToShow - 1; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      const status = habit.history[dateStr]?.status || 'none';
      days.push({ date: dateStr, status });
    }
    
    return days;
  };

  const days = getDayData();

  const handlePixelClick = (day: { date: string; status: 'completed' | 'skipped' | 'none' }, e: React.MouseEvent) => {
    const rect = e.currentTarget.getBoundingClientRect();
    setSelectedDay({ 
      date: day.date, 
      x: rect.left + rect.width / 2, 
      y: rect.top 
    });
  };

  const handleStatusChange = (status: 'completed' | 'skipped' | 'none') => {
    if (selectedDay && onDayClick) {
      onDayClick(selectedDay.date, status);
      setSelectedDay(null);
    }
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  };

  return (
    <div className="relative">
      <div 
        className="grid gap-1.5"
        style={{ 
          gridTemplateColumns: `repeat(${pixelsPerRow}, 1fr)`,
          gridTemplateRows: `repeat(${rows}, 1fr)`
        }}
      >
        {days.map((day, index) => {
          const isToday = day.date === new Date().toISOString().split('T')[0];
          
          return (
            <button
              key={day.date}
              onClick={(e) => handlePixelClick(day, e)}
              className={`aspect-square rounded transition-all hover:scale-110 active:scale-95 ${
                day.status === 'none' ? 'hover:bg-white/10' : ''
              }`}
              style={{
                backgroundColor: 
                  day.status === 'completed' 
                    ? habit.color
                    : day.status === 'skipped'
                    ? '#f59e0b40'
                    : isToday
                    ? '#ffffff15'
                    : '#ffffff08',
                boxShadow: day.status === 'completed' ? `0 0 8px ${habit.color}40` : 'none',
                outline: isToday ? `1.5px solid ${habit.color}60` : 'none',
                outlineOffset: '1px'
              }}
              aria-label={`${formatDate(day.date)}: ${day.status}`}
            />
          );
        })}
      </div>

      {/* Day Detail Popup */}
      {selectedDay && (
        <>
          <div 
            className="fixed inset-0 z-40" 
            onClick={() => setSelectedDay(null)}
          />
          <div
            className="fixed z-50 bg-[#1a2332] border border-white/10 rounded-2xl p-4 shadow-2xl animate-in fade-in zoom-in-95 duration-200"
            style={{
              left: `${selectedDay.x}px`,
              top: `${selectedDay.y - 10}px`,
              transform: 'translate(-50%, -100%)',
              minWidth: '200px'
            }}
          >
            <div className="flex items-start justify-between mb-3">
              <div>
                <p className="text-sm text-[#9aa3b2]">{formatDate(selectedDay.date)}</p>
                <p className="text-xs text-[#9aa3b2] mt-0.5">
                  {habit.history[selectedDay.date]?.status === 'completed' ? 'Completed' :
                   habit.history[selectedDay.date]?.status === 'skipped' ? 'Skipped' : 'Not tracked'}
                </p>
              </div>
              <button
                onClick={() => setSelectedDay(null)}
                className="p-1 hover:bg-white/5 rounded-lg transition-colors"
                aria-label="Close"
              >
                <X className="w-4 h-4 text-[#9aa3b2]" />
              </button>
            </div>

            <div className="flex gap-2">
              <button
                onClick={() => handleStatusChange('completed')}
                className="flex-1 py-2 px-3 rounded-xl text-sm transition-all hover:scale-105 active:scale-95"
                style={{ 
                  backgroundColor: `${habit.color}20`,
                  color: habit.color
                }}
              >
                Complete
              </button>
              <button
                onClick={() => handleStatusChange('skipped')}
                className="flex-1 py-2 px-3 bg-orange-500/20 text-orange-400 rounded-xl text-sm transition-all hover:scale-105 active:scale-95"
              >
                Skip
              </button>
              <button
                onClick={() => handleStatusChange('none')}
                className="flex-1 py-2 px-3 bg-white/5 text-[#9aa3b2] rounded-xl text-sm transition-all hover:scale-105 active:scale-95 hover:bg-white/10"
              >
                Clear
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
