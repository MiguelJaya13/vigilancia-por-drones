import { HashRouter, Navigate, Route, Routes } from 'react-router-dom';
import Ciudadelas from './pages/Ciudadelas.jsx';
import Monitoreo from './pages/Monitoreo.jsx';
import Bitacora from './pages/Bitacora.jsx';

export default function App() {
  return (
    <HashRouter>
      <Routes>
        <Route path="/" element={<Ciudadelas />} />
        <Route path="/monitoreo/:cdId" element={<Monitoreo />} />
        <Route path="/bitacora" element={<Navigate to="/bitacora/cd1" replace />} />
        <Route path="/bitacora/:cdId" element={<Bitacora />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </HashRouter>
  );
}
