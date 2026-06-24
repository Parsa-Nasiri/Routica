import { useState, useEffect } from 'react';
import { Plus, Settings, TrendingUp, Calendar } from 'lucide-react';
import { HabitCard } from './components/HabitCard';
import { HabitForm } from './components/HabitForm';
import { Analytics } from './components/Analytics';
import { SettingsPanel } from './components/SettingsPanel';
import { Toaster, toast } from 'sonner@2.0.3';

export interface Habit {
  id: string;
  title: string;
  description: string;
  iconId: string;
  color: string;
  frequencyGoal: number;
  frequencyPeriod: 'day' | 'week' | 'month';
  history: Record<string, { status: 'completed' | 'skipped' | 'none'; note?: string }>;
  createdAt: string;
  reminders: Array<{ time: string; days: string[] }>;
}

// Generate mock history data for demo
const generateMockHistory = (daysBack: number = 60) => {
  const history: Record<string, { status: 'completed' | 'skipped' | 'none' }> = {};
  const today = new Date();
  
  for (let i = 0; i < daysBack; i++) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    const dateStr = date.toISOString().split('T')[0];
    const rand = Math.random();
    history[dateStr] = { 
      status: rand > 0.3 ? 'completed' : rand > 0.15 ? 'none' : 'skipped'
    };
  }
  
  return history;
};

const initialHabits: Habit[] = [
  {
    id: '1',
    title: 'Morning Meditation',
    description: 'Start the day with 10 minutes of mindfulness',
    iconId: 'brain',
    color: '#8b5cf6',
    frequencyGoal: 7,
    frequencyPeriod: 'week',
    history: generateMockHistory(),
    createdAt: new Date().toISOString(),
    reminders: [{ time: '07:00', days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] }]
  },
  {
    id: '2',
    title: 'Exercise',
    description: 'At least 30 minutes of physical activity',
    iconId: 'dumbbell',
    color: '#f59e0b',
    frequencyGoal: 5,
    frequencyPeriod: 'week',
    history: generateMockHistory(),
    createdAt: new Date().toISOString(),
    reminders: [{ time: '18:00', days: ['Mon', 'Wed', 'Fri'] }]
  },
  {
    id: '3',
    title: 'Read',
    description: 'Read for 20 minutes before bed',
    iconId: 'book',
    color: '#10b981',
    frequencyGoal: 1,
    frequencyPeriod: 'day',
    history: generateMockHistory(),
    createdAt: new Date().toISOString(),
    reminders: [{ time: '21:00', days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] }]
  },
  {
    id: '4',
    title: 'Hydration',
    description: 'Drink 8 glasses of water',
    iconId: 'droplet',
    color: '#3b82f6',
    frequencyGoal: 1,
    frequencyPeriod: 'day',
    history: generateMockHistory(),
    createdAt: new Date().toISOString(),
    reminders: []
  },
  {
    id: '5',
    title: 'Code Practice',
    description: 'Work on personal coding projects',
    iconId: 'code',
    color: '#ec4899',
    frequencyGoal: 4,
    frequencyPeriod: 'week',
    history: generateMockHistory(),
    createdAt: new Date().toISOString(),
    reminders: [{ time: '19:00', days: ['Mon', 'Tue', 'Thu', 'Sat'] }]
  }
];

type View = 'habits' | 'analytics' | 'settings';

export default function App() {
  const [habits, setHabits] = useState<Habit[]>(initialHabits);
  const [currentView, setCurrentView] = useState<View>('habits');
  const [editingHabit, setEditingHabit] = useState<Habit | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [draggedHabit, setDraggedHabit] = useState<string | null>(null);

  const getTodayDateStr = () => new Date().toISOString().split('T')[0];

  const toggleHabitToday = (habitId: string) => {
    setHabits(prev => prev.map(habit => {
      if (habit.id !== habitId) return habit;
      
      const today = getTodayDateStr();
      const currentStatus = habit.history[today]?.status || 'none';
      const newStatus = currentStatus === 'completed' ? 'none' : 'completed';
      
      return {
        ...habit,
        history: {
          ...habit.history,
          [today]: { status: newStatus }
        }
      };
    }));
    
    const habit = habits.find(h => h.id === habitId);
    const newStatus = habit?.history[getTodayDateStr()]?.status === 'completed' ? 'unmarked' : 'marked';
    toast.success(newStatus === 'marked' ? '✓ Habit completed!' : 'Habit unmarked', {
      duration: 2000
    });
  };

  const updateDayStatus = (habitId: string, date: string, status: 'completed' | 'skipped' | 'none', note?: string) => {
    setHabits(prev => prev.map(habit => {
      if (habit.id !== habitId) return habit;
      
      return {
        ...habit,
        history: {
          ...habit.history,
          [date]: { status, note }
        }
      };
    }));
  };

  const saveHabit = (habit: Omit<Habit, 'id' | 'createdAt'>) => {
    if (editingHabit) {
      setHabits(prev => prev.map(h => 
        h.id === editingHabit.id 
          ? { ...habit, id: h.id, createdAt: h.createdAt }
          : h
      ));
      toast.success('Habit updated!');
    } else {
      const newHabit: Habit = {
        ...habit,
        id: Date.now().toString(),
        createdAt: new Date().toISOString(),
        history: {}
      };
      setHabits(prev => [...prev, newHabit]);
      toast.success('Habit created!');
    }
    
    setShowForm(false);
    setEditingHabit(null);
  };

  const deleteHabit = (habitId: string) => {
    const habit = habits.find(h => h.id === habitId);
    setHabits(prev => prev.filter(h => h.id !== habitId));
    toast.success('Habit deleted', {
      action: {
        label: 'Undo',
        onClick: () => {
          if (habit) {
            setHabits(prev => [...prev, habit]);
            toast.success('Habit restored');
          }
        }
      }
    });
  };

  const handleEdit = (habitId: string) => {
    const habit = habits.find(h => h.id === habitId);
    if (habit) {
      setEditingHabit(habit);
      setShowForm(true);
    }
  };

  const handleDragStart = (habitId: string) => {
    setDraggedHabit(habitId);
  };

  const handleDragOver = (e: React.DragEvent, targetHabitId: string) => {
    e.preventDefault();
    if (!draggedHabit || draggedHabit === targetHabitId) return;

    setHabits(prev => {
      const draggedIdx = prev.findIndex(h => h.id === draggedHabit);
      const targetIdx = prev.findIndex(h => h.id === targetHabitId);
      
      const newHabits = [...prev];
      const [removed] = newHabits.splice(draggedIdx, 1);
      newHabits.splice(targetIdx, 0, removed);
      
      return newHabits;
    });
  };

  const handleDragEnd = () => {
    setDraggedHabit(null);
  };

  if (showForm) {
    return (
      <>
        <HabitForm
          habit={editingHabit}
          onSave={saveHabit}
          onCancel={() => {
            setShowForm(false);
            setEditingHabit(null);
          }}
        />
        <Toaster position="top-center" theme="dark" />
      </>
    );
  }

  return (
    <div className="min-h-screen bg-[#0f1722] text-white">
      <Toaster position="top-center" theme="dark" />
      
      {/* Header */}
      <header className="sticky top-0 z-10 bg-[#0b1220]/95 backdrop-blur-sm border-b border-white/5">
        <div className="max-w-4xl mx-auto px-6 py-4 flex items-center justify-between">
          <h1 className="tracking-tight">HabitFlow</h1>
          
          <div className="flex items-center gap-3">
            <button
              onClick={() => setCurrentView('analytics')}
              className={`p-2 rounded-xl transition-colors ${
                currentView === 'analytics' 
                  ? 'bg-white/10 text-white' 
                  : 'text-[#9aa3b2] hover:text-white hover:bg-white/5'
              }`}
              aria-label="Analytics"
            >
              <TrendingUp className="w-5 h-5" />
            </button>
            
            <button
              onClick={() => setCurrentView('settings')}
              className={`p-2 rounded-xl transition-colors ${
                currentView === 'settings' 
                  ? 'bg-white/10 text-white' 
                  : 'text-[#9aa3b2] hover:text-white hover:bg-white/5'
              }`}
              aria-label="Settings"
            >
              <Settings className="w-5 h-5" />
            </button>
            
            {currentView === 'habits' && (
              <button
                onClick={() => {
                  setEditingHabit(null);
                  setShowForm(true);
                }}
                className="p-2 bg-[#2b2eee] hover:bg-[#2b2eee]/90 rounded-xl transition-all hover:scale-105 active:scale-95"
                aria-label="Add habit"
              >
                <Plus className="w-5 h-5" />
              </button>
            )}
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-6xl mx-auto px-6 py-8">
        {currentView === 'habits' && (
          <div className="space-y-6">
            {habits.length === 0 ? (
              <div className="text-center py-20">
                <div className="inline-flex items-center justify-center w-16 h-16 bg-white/5 rounded-full mb-4">
                  <Calendar className="w-8 h-8 text-[#9aa3b2]" />
                </div>
                <p className="text-[#9aa3b2] mb-4">No habits yet. Start building your routine!</p>
                <button
                  onClick={() => setShowForm(true)}
                  className="inline-flex items-center gap-2 px-6 py-3 bg-[#2b2eee] hover:bg-[#2b2eee]/90 rounded-xl transition-all hover:scale-105"
                >
                  <Plus className="w-5 h-5" />
                  Create Your First Habit
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                {habits.map(habit => (
                  <HabitCard
                    key={habit.id}
                    habit={habit}
                    onToggle={() => toggleHabitToday(habit.id)}
                    onEdit={() => handleEdit(habit.id)}
                    onDelete={() => deleteHabit(habit.id)}
                    onUpdateDay={updateDayStatus}
                    onDragStart={handleDragStart}
                    onDragOver={handleDragOver}
                    onDragEnd={handleDragEnd}
                  />
                ))}
              </div>
            )}
          </div>
        )}

        {currentView === 'analytics' && (
          <Analytics habits={habits} onBack={() => setCurrentView('habits')} />
        )}

        {currentView === 'settings' && (
          <SettingsPanel onBack={() => setCurrentView('habits')} />
        )}
      </main>
    </div>
  );
}