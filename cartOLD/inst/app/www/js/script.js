/*
 * ══════════════════════════════════════════════════════════════════════════════
 * FICHIER     : script.js 
 * AUTEUR      : MJ Martinat
 * DATE        : Décembre 2025
 * ORGANISATION: DDT de la Drôme 
 * DESCRIPTION : JavaScript principal pour cartOLD
 *               - Autocomplete BAN (Base Adresse Nationale)
 *               - Gestion échelles carte
 *               - Export/impression carte - CAPTURE RECALÉE
 *               - Module aide overlay
 *               - OUTIL MESURE DE DISTANCE
 *               - Surbrillance OLD50m au survol + clic
 * ══════════════════════════════════════════════════════════════════════════════
 */

(function() {
  'use strict';

  // ════════════════════════════════════════════════════════════════════════════
  // ÉTAT GLOBAL
  // ════════════════════════════════════════════════════════════════════════════
  const state = {
    banCommune: null,
    communesOld200: [],
    banResults: [],
    initialized: false,
    avertissementShown: false,
    fetchTimeout: null,
    old50mHoverInputId: null,
    highlightLayer: null,
    // ─── MESURE DISTANCE ───
    mesureValeurId: null,
    measureMode: false,
    measurePoints: [],
    measurePolyline: null,
    measureMarkers: [],
    measureTooltip: null,
    measureInitialized: false
  };

  const log = (...args) => {
    console.log('[cartOLD][JS]', ...args);
  };

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER : RÉCUPÉRER LA CARTE LEAFLET
  // ════════════════════════════════════════════════════════════════════════════
  function findLeafletMap(targetId = null) {
    if (!window.HTMLWidgets) {
      return null;
    }

    const lookupInstance = (id) => {
      const el = document.getElementById(id);
      if (!el) return null;

      let widget = HTMLWidgets.find('#' + id);
      if (!widget && HTMLWidgets.findAll) {
        widget = HTMLWidgets.findAll().find(w => w.getId && w.getId() === id);
      }

      return widget && widget.getMap ? widget.getMap() : null;
    };

    if (targetId) {
      const map = lookupInstance(targetId);
      if (map) return map;
    }

    const els = document.querySelectorAll('.leaflet.html-widget');
    for (const el of els) {
      const map = lookupInstance(el.id);
      if (map) return map;
    }

    return null;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MODALE AVERTISSEMENT
  // ════════════════════════════════════════════════════════════════════════════
  function showAvertissementModal() {
    if (state.avertissementShown || !window.jQuery) return;

    if (sessionStorage.getItem('avertissementShown') === 'true') {
      state.avertissementShown = true;
      return;
    }

    state.avertissementShown = true;
    sessionStorage.setItem('avertissementShown', 'true');

    const $ = window.jQuery;

    const modal = $(
      '<div class="modal fade" id="avertissementModal" tabindex="-1" role="dialog" style="display:block;">\
        <div class="modal-dialog modal-lg" role="document">\
          <div class="modal-content">\
            <div class="modal-header" style="background: linear-gradient(120deg, rgba(70, 95, 157, 0.75), rgba(70, 95, 157, 0.85), rgba(70, 95, 157, 1)); color:white;">\
              <h4 class="modal-title">⚠️ AVERTISSEMENT</h4>\
            </div>\
            <div class="modal-body">\
              <div id="avertissement-content" style="padding:20px;">\
                <div style="text-align:center;padding:40px;">\
                  <div class="spinner"></div>\
                  <p style="margin-top:20px;">Chargement...</p>\
                </div>\
              </div>\
            </div>\
            <div class="modal-footer">\
              <button type="button" class="btn btn-primary btn-lg" data-dismiss="modal">J\'ai compris</button>\
            </div>\
          </div>\
        </div>\
      </div>'
    );

    $('body').append(modal);

    fetch('www/html/avertissement.html')
      .then(r => r.ok ? r.text() : Promise.reject(r))
      .then(html => {
        const c = document.getElementById('avertissement-content');
        if (c) c.innerHTML = html;
      })
      .catch(err => {
        console.error('[cartOLD] Erreur chargement avertissement:', err);
        const c = document.getElementById('avertissement-content');
        if (c) c.innerHTML = "<p style='color:#dc3545;'>Impossible de charger le message.</p>";
      });

    modal.modal('show');
    modal.on('hidden.bs.modal', () => modal.remove());
  }

  // ════════════════════════════════════════════════════════════════════════════
  // GESTION ÉCHELLES
  // ════════════════════════════════════════════════════════════════════════════
  function niceDistance(m) {
    if (!m || !isFinite(m) || m <= 0) return 0;
    const pow = Math.pow(10, Math.floor(Math.log10(m)));
    const x = m / pow;
    return (x < 1.5 ? 1 : (x < 3 ? 2 : (x < 7 ? 5 : 10))) * pow;
  }

  function updateScales(map) {
    if (!map) return;

    const numInput   = document.querySelector('[id$="echelle_num_valeur"]');
    const graphValue = document.querySelector('[id$="echelle_graph_valeur"]');
    const graphBar   = document.querySelector('.barre-echelle-graph');

    const cont = map.getContainer();
    if (!cont) return;

    const W = cont.clientWidth;
    if (W <= 0) return;

    const midY = cont.clientHeight / 2;
    const left   = map.containerPointToLatLng([0, midY]);
    const right  = map.containerPointToLatLng([W, midY]);
    const meters = map.distance(left, right);
    const metersPerPixel = meters / W;

    const physicalMetersPerPixel = 0.000264583;
    const scale = Math.round(metersPerPixel / physicalMetersPerPixel);

    if (numInput && isFinite(scale)) {
      numInput.value = scale.toLocaleString('fr-FR');
      numInput.dispatchEvent(new Event('input', { bubbles: true }));
    }

    if (graphValue && graphBar && isFinite(metersPerPixel)) {
      const dist = niceDistance(metersPerPixel * 120);
      const px = Math.max(40, Math.min(160, dist / metersPerPixel));
      graphBar.style.width = px + 'px';

      graphValue.textContent = dist >= 1000
        ? (dist / 1000).toLocaleString('fr-FR') + ' km'
        : Math.round(dist).toLocaleString('fr-FR') + ' m';
    }
  }

  function attachScaleListeners(map) {
    if (!map) return;
    updateScales(map);
    map.on('zoomend moveend', () => updateScales(map));
  }

  // ════════════════════════════════════════════════════════════════════════════
  // OUTIL DE MESURE DE DISTANCE (STYLE QGIS)
  // ════════════════════════════════════════════════════════════════════════════

  function formatDistance(meters) {
    if (meters >= 1000) {
      return (meters / 1000).toFixed(2) + ' km';
    }
    return Math.round(meters) + ' m';
  }

  function calculateTotalDistance(points, map) {
    if (!map || points.length < 2) return 0;
    let total = 0;
    for (let i = 1; i < points.length; i++) {
      total += map.distance(points[i - 1], points[i]);
    }
    return total;
  }

  const measureStore = {
    measurements: [],
    currentMeasure: null
  };

  function createNewMeasure() {
    return {
      points: [],
      polyline: null,
      markers: [],
      tooltip: null,
      segmentLabels: []
    };
  }

  function removeMeasureFromMap(measure, map) {
    if (!map || !measure) return;

    if (measure.polyline && map.hasLayer(measure.polyline)) {
      map.removeLayer(measure.polyline);
    }
    measure.markers.forEach(m => {
      if (map.hasLayer(m)) map.removeLayer(m);
    });
    if (measure.tooltip && map.hasLayer(measure.tooltip)) {
      map.removeLayer(measure.tooltip);
    }
    measure.segmentLabels.forEach(lbl => {
      if (map.hasLayer(lbl)) map.removeLayer(lbl);
    });
  }

  function clearAllMeasures(map) {
    if (!map) return;

    measureStore.measurements.forEach(m => removeMeasureFromMap(m, map));
    measureStore.measurements = [];

    if (measureStore.currentMeasure) {
      removeMeasureFromMap(measureStore.currentMeasure, map);
      measureStore.currentMeasure = null;
    }

    log('Toutes les mesures effacées');
  }

  function updateCurrentMeasureDisplay(map) {
    const measure = measureStore.currentMeasure;
    if (!map || !measure || measure.points.length < 1) return;

    if (measure.polyline) {
      measure.polyline.setLatLngs(measure.points);
    } else if (measure.points.length >= 2) {
      measure.polyline = L.polyline(measure.points, {
        color: '#FF6600',
        weight: 3,
        opacity: 0.9,
        interactive: false
      }).addTo(map);
    }

    if (measure.points.length >= 2) {
      measure.segmentLabels.forEach(lbl => {
        if (map.hasLayer(lbl)) map.removeLayer(lbl);
      });
      measure.segmentLabels = [];

      for (let i = 1; i < measure.points.length; i++) {
        const segDist = map.distance(measure.points[i-1], measure.points[i]);
        const midLat = (measure.points[i-1].lat + measure.points[i].lat) / 2;
        const midLng = (measure.points[i-1].lng + measure.points[i].lng) / 2;

        const segLabel = L.tooltip({
          permanent: true,
          direction: 'center',
          className: 'measure-segment-label',
          offset: [0, 0]
        })
          .setLatLng([midLat, midLng])
          .setContent('<span class="segment-dist">' + formatDistance(segDist) + '</span>')
          .addTo(map);

        measure.segmentLabels.push(segLabel);
      }
    }

    if (measure.points.length >= 2) {
      const totalDist = calculateTotalDistance(measure.points, map);
      const lastPoint = measure.points[measure.points.length - 1];

      const content = '<div class="measure-tooltip-total"><strong>Total : ' + formatDistance(totalDist) + '</strong></div>';

      if (measure.tooltip) {
        measure.tooltip.setLatLng(lastPoint);
        measure.tooltip.setContent(content);
      } else {
        measure.tooltip = L.tooltip({
          permanent: true,
          direction: 'top',
          className: 'measure-tooltip-container',
          offset: [0, -12]
        })
          .setLatLng(lastPoint)
          .setContent(content)
          .addTo(map);
      }

      if (state.mesureValeurId) {
        const el = document.getElementById(state.mesureValeurId);
        if (el && measure.points.length >= 2) {
          const totalDist = calculateTotalDistance(measure.points, map);
          el.textContent = formatDistance(totalDist);
        }
      }
    }
  }

  function finalizeMeasure(map) {
    if (!measureStore.currentMeasure || measureStore.currentMeasure.points.length < 2) {
      if (measureStore.currentMeasure) {
        removeMeasureFromMap(measureStore.currentMeasure, map);
        measureStore.currentMeasure = null;
      }
      return;
    }

    if (measureStore.currentMeasure.polyline) {
      measureStore.currentMeasure.polyline.setStyle({
        color: '#3388ff',
        weight: 3,
        dashArray: null
      });
    }

    measureStore.measurements.push(measureStore.currentMeasure);
    measureStore.currentMeasure = null;

    log('Mesure finalisée, total stockées:', measureStore.measurements.length);
  }

  function toggleMeasureMode(map) {
    if (!map) return;

    state.measureMode = !state.measureMode;
    const btn = document.querySelector('.btn-mesure');

    if (state.measureMode) {
      if (btn) btn.classList.add('active');
      document.body.classList.add('measure-mode-active');
      map.getContainer().style.cursor = 'crosshair';
      map.doubleClickZoom.disable();
      measureStore.currentMeasure = createNewMeasure();
      log('Mode mesure ACTIVÉ');
    } else {
      if (btn) btn.classList.remove('active');
      document.body.classList.remove('measure-mode-active');
      map.getContainer().style.cursor = '';
      map.doubleClickZoom.enable();
      finalizeMeasure(map);
      log('Mode mesure DÉSACTIVÉ');
    }
    if (!state.measureMode && state.mesureValeurId) {
      const el = document.getElementById(state.mesureValeurId);
      if (el) el.textContent = "Aucune mesure en cours";
    }
  }

  function handleMeasureClick(e, map) {
    if (!state.measureMode || !map) return;

    if (!measureStore.currentMeasure) {
      measureStore.currentMeasure = createNewMeasure();
    }

    const latlng = e.latlng;
    measureStore.currentMeasure.points.push(latlng);

    const marker = L.circleMarker(latlng, {
      radius: 5,
      color: '#FF6600',
      fillColor: '#ffffff',
      fillOpacity: 1,
      weight: 2,
      interactive: false
    }).addTo(map);

    measureStore.currentMeasure.markers.push(marker);
    updateCurrentMeasureDisplay(map);
  }

  function initMeasureTool(map) {
    if (!map || state.measureInitialized) return;

    const btnMesure = document.querySelector('.btn-mesure');
    const btnClear = document.querySelector('.btn-mesure-clear');

    if (!btnMesure) {
      log('Bouton mesure non trouvé, retry dans 500ms');
      setTimeout(() => initMeasureTool(map), 500);
      return;
    }

    log('Initialisation outil mesure QGIS-style...');

    btnMesure.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      toggleMeasureMode(map);
    });

    if (btnClear) {
      btnClear.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        clearAllMeasures(map);

        if (state.measureMode) {
          state.measureMode = false;
          const btn = document.querySelector('.btn-mesure');
          if (btn) btn.classList.remove('active');
          map.getContainer().style.cursor = '';
          map.doubleClickZoom.enable();
        }
      });
    }

    map.on('click', function(e) {
      if (state.measureMode) {
        handleMeasureClick(e, map);
      }
    });

    map.on('dblclick', function(e) {
      if (state.measureMode) {
        L.DomEvent.stop(e);
        finalizeMeasure(map);
        measureStore.currentMeasure = createNewMeasure();
        log('Mesure terminée, nouvelle mesure prête');
      }
    });

    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && state.measureMode) {
        if (measureStore.currentMeasure) {
          removeMeasureFromMap(measureStore.currentMeasure, map);
          measureStore.currentMeasure = createNewMeasure();
          log('Mesure en cours annulée');
        }
      }
    });

    state.measureInitialized = true;
    log('Outil mesure QGIS-style initialisé ✓');
  }

  // ════════════════════════════════════════════════════════════════════════════
  // AUTOCOMPLETE BAN
  // ════════════════════════════════════════════════════════════════════════════
  function setBanSelection(label, lon, lat) {
    const L = document.querySelector('[id$="adresse_sel_label"]');
    const X = document.querySelector('[id$="adresse_sel_lon"]');
    const Y = document.querySelector('[id$="adresse_sel_lat"]');

    if (L) L.value = label || '';
    if (X) X.value = lon ?? '';
    if (Y) Y.value = lat ?? '';

    if (window.Shiny) {
      if (L) Shiny.setInputValue(L.id, label || '', { priority: 'event' });
      if (X) Shiny.setInputValue(X.id, lon ?? null, { priority: 'event' });
      if (Y) Shiny.setInputValue(Y.id, lat ?? null, { priority: 'event' });
    }
  }

  function buildDatalist(input) {
    const id = input.id + '-list';

    let list = document.getElementById(id);
    if (!list) {
      list = document.createElement('datalist');
      list.id = id;
      input.setAttribute('list', id);
      input.parentNode.appendChild(list);
    }
    return list;
  }

  async function fetchBanSuggestions(input) {
    const q = input.value.trim();
    const list = buildDatalist(input);

    const minChars = state.banCommune ? 2 : 3;
    if (q.length < minChars) {
      list.innerHTML = '';
      state.banResults = [];
      return;
    }

    const endpoint = 'https://api-adresse.data.gouv.fr/search/';
    const params = new URLSearchParams({
      q: q,
      limit: '15',
      autocomplete: '1'
    });

    if (state.banCommune) {
      params.set('citycode', state.banCommune);
    } else {
      params.set('lat', '44.9333');
      params.set('lon', '4.8917');
    }

    try {
      const url = endpoint + '?' + params.toString();
      const r = await fetch(url);
      if (!r.ok) {
        list.innerHTML = '';
        state.banResults = [];
        return;
      }

      const data = await r.json();

      let filtered = data.features ?? [];
      if (!state.banCommune) {
        filtered = filtered.filter(f => {
          const ctx = f?.properties?.context || '';
          const postcode = f?.properties?.postcode || '';
          return ctx.includes('26,') || ctx.includes('Drôme') || postcode.startsWith('26');
        });
      }

      state.banResults = filtered.slice(0, 10);
      list.innerHTML = '';

      if (state.banResults.length === 0) {
        const opt = document.createElement('option');
        opt.value = state.banCommune
          ? 'Aucune adresse trouvée dans cette commune'
          : 'Aucune adresse trouvée dans la Drôme';
        opt.disabled = true;
        list.appendChild(opt);
        return;
      }

      state.banResults.forEach((f, i) => {
        const opt = document.createElement('option');
        const label = f?.properties?.label ?? `Adresse ${i + 1}`;
        opt.value = label;
        list.appendChild(opt);
      });

    } catch (e) {
      console.error('[cartOLD] BAN error:', e);
      list.innerHTML = '';
      state.banResults = [];
    }
  }

  function initBanAutocomplete() {
    const input = document.querySelector('[id$="adresse_input"]');
    if (!input || input.dataset.banReady === 'true') return;

    input.dataset.banReady = 'true';
    log('BAN autocomplete initialisé');

    input.addEventListener('input', () => {
      clearTimeout(state.fetchTimeout);
      state.fetchTimeout = setTimeout(() => {
        fetchBanSuggestions(input);
      }, 100);
    });

    input.addEventListener('change', () => {
      const label = input.value;
      const match = state.banResults.find(f => f.properties?.label === label);

      if (match) {
        const [lon, lat] = match.geometry.coordinates;
        setBanSelection(match.properties.label, lon, lat);

        const code = match.properties.citycode || null;
        if (window.Shiny && code) {
          Shiny.setInputValue('adresse_commune_info',
            { code_insee: code }, { priority: 'event' });
        }
      }
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // EXPORT CARTE - HYBRIDE : html2canvas (tuiles) + dessin manuel (vecteurs)
  // ════════════════════════════════════════════════════════════════════════════

  function initCaptureHandler() {
    if (!window.Shiny) return;

    Shiny.addCustomMessageHandler('capture-map', async function(msg) {
      log('=== DEBUT CAPTURE HYBRIDE ===');

      // ─── 1. TROUVER LA CARTE ───
      let map = findLeafletMap(msg.mapId);
      if (!map) {
        console.error('[cartOLD] Carte non trouvée');
        return;
      }

      const container = map.getContainer();
      const size = map.getSize();
      const width = size.x;
      const height = size.y;
      const scale = 2;

      log('Dimensions:', width, 'x', height);
      log('Zoom:', map.getZoom());
      log('Center:', map.getCenter());

      // ─── 2. CRÉER LE CANVAS FINAL ───
      const canvas = document.createElement('canvas');
      canvas.width = width * scale;
      canvas.height = height * scale;
      const ctx = canvas.getContext('2d');
      ctx.scale(scale, scale);

      // ─── 3. FOND DE CARTE (html2canvas ou fond blanc) ───
      if (typeof html2canvas === 'function') {
        try {
          log('Capture tuiles avec html2canvas...');

          // Masquer les contrôles ET les vecteurs temporairement
          const controls = container.querySelector('.leaflet-control-container');
          const overlayPane = container.querySelector('.leaflet-overlay-pane');
          const markerPane = container.querySelector('.leaflet-marker-pane');
          const popupPane = container.querySelector('.leaflet-popup-pane');
          const tooltipPane = container.querySelector('.leaflet-tooltip-pane');

          if (controls) controls.style.visibility = 'hidden';
          if (overlayPane) overlayPane.style.visibility = 'hidden';
          if (markerPane) markerPane.style.visibility = 'hidden';
          if (popupPane) popupPane.style.visibility = 'hidden';
          if (tooltipPane) tooltipPane.style.visibility = 'hidden';

          // Capturer uniquement les tuiles
          const tilesCanvas = await html2canvas(container, {
            useCORS: true,
            allowTaint: true,
            scale: 1,
            backgroundColor: '#ffffff',
            logging: false,
            width: width,
            height: height
          });

          // Restaurer
          if (controls) controls.style.visibility = '';
          if (overlayPane) overlayPane.style.visibility = '';
          if (markerPane) markerPane.style.visibility = '';
          if (popupPane) popupPane.style.visibility = '';
          if (tooltipPane) tooltipPane.style.visibility = '';

          log('tilesCanvas size:', tilesCanvas.width, 'x', tilesCanvas.height);

          // Dessiner les tuiles sur notre canvas
          ctx.drawImage(tilesCanvas, 0, 0, width, height);
          log('Tuiles capturées ✓');

        } catch (e) {
          log('html2canvas échoué:', e.message);
          ctx.fillStyle = '#f0f0f0';
          ctx.fillRect(0, 0, width, height);
        }
      } else {
        log('html2canvas non disponible - fond gris');
        ctx.fillStyle = '#f0f0f0';
        ctx.fillRect(0, 0, width, height);
      }

      // ─── 4. DESSINER LES COUCHES VECTORIELLES PAR-DESSUS ───
      log('Dessin des couches vectorielles...');

      let layerCount = 0;

      map.eachLayer(function(layer) {
        try {
          // Ignorer les TileLayers
          if (layer instanceof L.TileLayer) return;

          // ── Polygones et Polylines directs ──
          if (layer instanceof L.Polygon || layer instanceof L.Polyline) {
            drawLayerToCanvas(ctx, layer, map);
            layerCount++;
          }

          // ── FeatureGroup / LayerGroup / GeoJSON (contient des sous-couches) ──
          else if (layer.eachLayer) {
            layer.eachLayer(function(sublayer) {
              if (sublayer instanceof L.Polygon || sublayer instanceof L.Polyline) {
                drawLayerToCanvas(ctx, sublayer, map);
                layerCount++;
              }
              else if (sublayer instanceof L.CircleMarker) {
                drawCircleMarkerToCanvas(ctx, sublayer, map);
                layerCount++;
              }
            });
          }

          // ── CircleMarkers ──
          else if (layer instanceof L.CircleMarker) {
            drawCircleMarkerToCanvas(ctx, layer, map);
            layerCount++;
          }

        } catch (e) {
          log('Erreur layer:', e.message);
        }
      });

      log('Couches vectorielles dessinées:', layerCount, 'couches');

      // ─── 5. ATTRIBUTION ───
      ctx.fillStyle = 'rgba(255, 255, 255, 0.9)';
      ctx.fillRect(width - 230, height - 24, 230, 24);
      ctx.fillStyle = '#333333';
      ctx.font = 'bold 11px Arial, sans-serif';
      ctx.textAlign = 'right';
      ctx.fillText('© OpenStreetMap | IGN | DDT26', width - 8, height - 8);

      // ─── 6. ENVOYER ───
      const dataUrl = canvas.toDataURL('image/png', 1.0);
      log('=== CAPTURE HYBRIDE TERMINÉE ===');

      Shiny.setInputValue(msg.outputId, dataUrl, { priority: 'event' });
    });
  }

  // ─── Helper : dessiner un polygon/polyline sur le canvas ───
  function drawLayerToCanvas(ctx, layer, map) {
    const latlngs = layer.getLatLngs();
    const options = layer.options || {};
    const isPolygon = layer instanceof L.Polygon;

    drawPathToCanvas(ctx, latlngs, options, isPolygon, map);
  }

  // ─── Helper : dessiner un path (récursif pour multi-polygones) ───
  function drawPathToCanvas(ctx, coords, options, isPolygon, map) {
    if (!coords || coords.length === 0) return;

    // Si c'est un tableau de tableaux (multi-polygon ou polygon avec trous)
    if (Array.isArray(coords[0]) && coords[0].lat === undefined) {
      coords.forEach(ring => drawPathToCanvas(ctx, ring, options, isPolygon, map));
      return;
    }

    ctx.beginPath();

    coords.forEach((latlng, i) => {
      const point = map.latLngToContainerPoint(latlng);
      if (i === 0) {
        ctx.moveTo(point.x, point.y);
      } else {
        ctx.lineTo(point.x, point.y);
      }
    });

    if (isPolygon) {
      ctx.closePath();
    }

    // Remplissage
    if (options.fill !== false && (options.fillColor || options.color)) {
      ctx.fillStyle = options.fillColor || options.color || '#3388ff';
      ctx.globalAlpha = options.fillOpacity ?? 0.2;
      ctx.fill();
    }

    // Contour
    if (options.stroke !== false) {
      ctx.strokeStyle = options.color || '#3388ff';
      ctx.lineWidth = options.weight || 3;
      ctx.globalAlpha = options.opacity ?? 1;

      if (options.dashArray) {
        const dashes = String(options.dashArray).split(',').map(d => parseFloat(d.trim()));
        ctx.setLineDash(dashes);
      } else {
        ctx.setLineDash([]);
      }

      ctx.stroke();
    }

    // Reset
    ctx.globalAlpha = 1;
    ctx.setLineDash([]);
  }

  // ─── Helper : dessiner un CircleMarker ───
  function drawCircleMarkerToCanvas(ctx, layer, map) {
    const latlng = layer.getLatLng();
    const point = map.latLngToContainerPoint(latlng);
    const radius = layer.getRadius ? layer.getRadius() : (layer.options.radius || 10);
    const options = layer.options || {};

    ctx.beginPath();
    ctx.arc(point.x, point.y, radius, 0, Math.PI * 2);

    if (options.fill !== false && (options.fillColor || options.color)) {
      ctx.fillStyle = options.fillColor || options.color || '#3388ff';
      ctx.globalAlpha = options.fillOpacity ?? 0.2;
      ctx.fill();
    }

    if (options.stroke !== false) {
      ctx.strokeStyle = options.color || '#3388ff';
      ctx.lineWidth = options.weight || 3;
      ctx.globalAlpha = options.opacity ?? 1;
      ctx.stroke();
    }

    ctx.globalAlpha = 1;
  }

  function initPrintHandler() {
    if (!window.Shiny) return;

    Shiny.addCustomMessageHandler('print-image', msg => {
      if (!msg?.imageData) return;

      const win = window.open('', '_blank');
      win.document.write('<html><body style="margin:0;">');
      win.document.write(`<img src="${msg.imageData}" style="width:100%;">`);
      win.document.write('</body></html>');
      win.document.close();

      setTimeout(() => {
        win.print();
        win.close();
      }, 250);
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SURBRILLANCE OLD50M (HOVER + CLIC)
  // ════════════════════════════════════════════════════════════════════════════

  function clearOld50mHighlight(map) {
    if (state.highlightLayer) {
      try {
        if (map && map.hasLayer(state.highlightLayer)) {
          map.removeLayer(state.highlightLayer);
        }
      } catch (e) { /* ignore */ }
      state.highlightLayer = null;
    }
  }

  function applyOld50mHighlight(layer, map) {
    if (!map || !layer) return;

    clearOld50mHighlight(map);

    try {
      const gj = layer.toGeoJSON();
      state.highlightLayer = L.geoJSON(gj, {
        style: {
          weight: 4,
          color: '#FF6600',
          fillColor: '#FF6600',
          fillOpacity: 0.5,
          dashArray: ''
        },
        interactive: false
      }).addTo(map);

      state.highlightLayer.bringToFront();
    } catch (err) {
      console.error('[cartOLD][HIGHLIGHT] Erreur:', err);
    }
  }

  function bindOld50mHover() {
    const map = findLeafletMap();
    if (!map) return;

    const layers = [];

    map.eachLayer(function(layer) {
      if (layer && layer.options && layer.options.className === 'old50m-polygon') {
        layers.push(layer);
      }
    });

    if (layers.length === 0) return;

    log('Binding hover sur', layers.length, 'polygones OLD50m');

    layers.forEach(layer => {
      layer.off('mouseover.old50m mouseout.old50m click.old50m');

      layer.on('mouseover.old50m', function(e) {
        if (state.measureMode) return;
        applyOld50mHighlight(e.target, map);
      });

      layer.on('mouseout.old50m', function() {
        clearOld50mHighlight(map);
      });

      layer.on('click.old50m', function(e) {
        if (state.measureMode) return;
        if (!window.Shiny) return;

        const inputId = state.old50mHoverInputId || findOld50mInputId();
        if (!inputId) {
          log('old50mHoverInputId non défini');
          return;
        }

        L.DomEvent.stopPropagation(e);

        const props = e.target.feature?.properties || {};
        const payload = {
          comptecommunal: props.comptecommunal ?? null,
          geo_parcelle:   props.geo_parcelle ?? null,
          geo_section:    props.geo_section  ?? null,
          idu:            props.idu          ?? null
        };

        log('OLD50m CLIC → Shiny:', payload);
        Shiny.setInputValue(inputId, payload, { priority: 'event' });
      });
    });
  }

  function findOld50mInputId() {
    const inputs = document.querySelectorAll('input[id$="-old50m_hover_info"]');
    if (inputs.length > 0) {
      return inputs[0].id;
    }
    const carte = document.querySelector('[id$="-carte"]');
    if (carte) {
      const ns = carte.id.replace('-carte', '');
      return ns + '-old50m_hover_info';
    }
    return null;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HANDLERS MESSAGES SHINY (BAN + DEPT)
  // ════════════════════════════════════════════════════════════════════════════
  function initBanMessageHandlers() {
    if (!window.Shiny) return;

    Shiny.addCustomMessageHandler('setCommuneBAN', msg => {
      if (msg?.commune) {
        state.banCommune = msg.commune;
        log('Commune BAN fixée:', state.banCommune);
      }
    });

    Shiny.addCustomMessageHandler('resetBAN', msg => {
      state.banCommune = null;
      state.banResults = [];
      log('État BAN réinitialisé');

      const input = document.querySelector('[id$="adresse_input"]');
      if (input) {
        const list = buildDatalist(input);
        list.innerHTML = '';
      }
    });

    Shiny.addCustomMessageHandler('setCommunesOld200', msg => {
      if (msg?.communes && Array.isArray(msg.communes)) {
        state.communesOld200 = msg.communes;
        log('Communes OLD200 fixées:', state.communesOld200.length);
      }
    });

    Shiny.addCustomMessageHandler('forceDeptVisible', msg => {
      const map = findLeafletMap();
      if (!map) return;

      map.eachLayer(function(layer) {
        if (layer.options && layer.options.group === 'dept_lim') {
          if (!map.hasLayer(layer)) {
            map.addLayer(layer);
          }
        }
      });
    });

    Shiny.addCustomMessageHandler('communeLayersReady', msg => {
      log('Couches communales prêtes, rebind hover...');
      setTimeout(() => {
        bindOld50mHover();
        setTimeout(() => bindOld50mHover(), 500);
      }, 400);
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // INITIALISATION OUTILS CARTE
  // ════════════════════════════════════════════════════════════════════════════
  function initMapTools(message) {
    const mapId = message?.mapId ?? null;

    if (message?.old50mHoverInputId) {
      state.old50mHoverInputId = message.old50mHoverInputId;
    }
    if (message?.mesureValeurId) {
      state.mesureValeurId = message.mesureValeurId;
    }
    if (state.initialized) return;

    const map = findLeafletMap(mapId);
    if (!map) {
      setTimeout(() => initMapTools(message), 500);
      return;
    }

    log('Initialisation des outils carte...');

    attachScaleListeners(map);
    initBanAutocomplete();
    initCaptureHandler();
    initMeasureTool(map);

    const bindOld50mHoverDebounced = (function() {
      let t = null;
      return function() {
        clearTimeout(t);
        t = setTimeout(() => bindOld50mHover(), 300);
      };
    })();

    bindOld50mHoverDebounced();
    map.on('zoomend moveend', bindOld50mHoverDebounced);

    map.on('layeradd', function(e) {
      if (e.layer && e.layer.options && e.layer.options.className === 'old50m-polygon') {
        log('Couche OLD50m ajoutée, rebind...');
        bindOld50mHoverDebounced();
      }
    });

    state.initialized = true;
    log('Outils carte initialisés ✓');
  }

  // ════════════════════════════════════════════════════════════════════════════
  // AVERTISSEMENT : PLANIFICATION
  // ════════════════════════════════════════════════════════════════════════════
  function scheduleAvertissement() {
    if (state.avertissementShown) return;

    if (!window.jQuery) {
      setTimeout(scheduleAvertissement, 200);
      return;
    }

    if (document.readyState === 'complete' || document.readyState === 'interactive') {
      showAvertissementModal();
    } else {
      document.addEventListener('DOMContentLoaded', () => showAvertissementModal(), { once: true });
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SETUP GLOBAL
  // ════════════════════════════════════════════════════════════════════════════
  function setupShinyHandlers() {
    if (!window.Shiny) {
      setTimeout(setupShinyHandlers, 200);
      return;
    }

    Shiny.addCustomMessageHandler('initMapTools', msg => initMapTools(msg));
    initBanMessageHandlers();
    initPrintHandler();
    log('Handlers Shiny enregistrés');
  }

  setupShinyHandlers();
  scheduleAvertissement();

})();

// ══════════════════════════════════════════════════════════════════════════════
// EVENT : Shiny connecté
// ══════════════════════════════════════════════════════════════════════════════
document.addEventListener('shiny:connected', function() {
  console.log('[cartOLD] Shiny connecté');
});

// ══════════════════════════════════════════════════════════════════════════════
// SYSTÈME DE NAVIGATION DOCK (STYLE LIZMAP) - AVEC ROTATION TOGGLER 90°
// ══════════════════════════════════════════════════════════════════════════════
(function() {
  'use strict';

  function initDockNavigation() {
    if (!window.Shiny) {
      setTimeout(initDockNavigation, 200);
      return;
    }

    console.log('[cartOLD][Dock] Initialisation navigation...');

    Shiny.addCustomMessageHandler('openDockPanel', function(msg) {
      const panel = msg.panel;
      const dockId = msg.dockId;

      const dock = document.getElementById(dockId);
      if (!dock) {
        console.warn('[cartOLD][Dock] Dock non trouvé:', dockId);
        return;
      }

      const panels = dock.querySelectorAll('.dock-panel');
      panels.forEach(function(p) { p.classList.remove('panel-active'); });

      const targetPanel = dock.querySelector('[data-panel="' + panel + '"]');
      if (targetPanel) {
        targetPanel.classList.add('panel-active');
      }

      dock.classList.add('dock-open');
      document.body.classList.add('dock-is-open');

      updateNavButtons(panel);

      // TOGGLER : rotation 90° (classe .rotated)
      var menuToggle = document.getElementById('menuToggle');
      if (menuToggle) {
        menuToggle.classList.add('rotated');
        menuToggle.classList.remove('active');
      }

      console.log('[cartOLD][Dock] Panel ouvert:', panel);
    });

    Shiny.addCustomMessageHandler('closeDockPanels', function(msg) {
      var panels = document.querySelectorAll('.dock-panel');
      panels.forEach(function(p) { p.classList.remove('panel-active'); });
    });

    Shiny.addCustomMessageHandler('closeDock', function(msg) {
      var dockId = msg.dockId;
      var dock = document.getElementById(dockId);

      if (dock) {
        dock.classList.remove('dock-open');
        var panels = dock.querySelectorAll('.dock-panel');
        panels.forEach(function(p) { p.classList.remove('panel-active'); });
      }

      document.body.classList.remove('dock-is-open');
      updateNavButtons(null);

      // TOGGLER : retour horizontal
      var menuToggle = document.getElementById('menuToggle');
      if (menuToggle) {
        menuToggle.classList.remove('rotated');
        menuToggle.classList.remove('active');
      }

      console.log('[cartOLD][Dock] Dock fermé');
    });

    function updateNavButtons(activePanel) {
      var navBtns = document.querySelectorAll('.nav-btn');
      navBtns.forEach(function(btn) {
        btn.classList.remove('active', 'btn-active');
      });

      if (activePanel) {
        var panelMap = {
          'aide': 'btn_nav_aide',
          'localisation': 'btn_nav_loc',
          'couches': 'btn_nav_layer',
          'outils': 'btn_nav_outils',
          'export': 'btn_nav_export'
        };

        var btnSuffix = panelMap[activePanel];
        if (btnSuffix) {
          var activeBtn = document.querySelector('[id$="' + btnSuffix + '"]');
          if (activeBtn) {
            activeBtn.classList.add('active', 'btn-active');
          }
        }
      }
    }

    // ─── Clic sur bouton fermer (croix) du dock ───
    document.addEventListener('click', function(e) {
      var target = e.target;

      // Vérifier si c'est un bouton croix ou une icône dans un bouton croix
      var closeBtn = target.closest('.dock-close-btn, .btn-close-dock, [data-action="close-dock"]');

      // Vérifier aussi les icônes FontAwesome (fa-times, fa-xmark, fa-close)
      if (!closeBtn) {
        var icon = target.closest('i');
        if (icon && (icon.classList.contains('fa-times') ||
                     icon.classList.contains('fa-xmark') ||
                     icon.classList.contains('fa-close'))) {
          closeBtn = icon.parentElement;
        }
      }

      // Si c'est un bouton de fermeture dans le dock
      if (closeBtn && closeBtn.closest('.dock')) {
        e.preventDefault();
        e.stopPropagation();

        var dock = document.querySelector('.dock');
        if (dock) {
          dock.classList.remove('dock-open');
          var panels = dock.querySelectorAll('.dock-panel');
          panels.forEach(function(p) { p.classList.remove('panel-active'); });
        }

        document.body.classList.remove('dock-is-open');
        updateNavButtons(null);

        // TOGGLER : retour horizontal
        var menuToggle = document.getElementById('menuToggle');
        if (menuToggle) {
          menuToggle.classList.remove('rotated');
          menuToggle.classList.remove('active');
        }

        console.log('[cartOLD][Dock] Fermé via bouton croix');
      }
    });

    // ─── Clic sur menu toggle (hamburger) ───
    document.addEventListener('click', function(e) {
      var menuToggle = e.target.closest('#menuToggle');
      if (menuToggle) {
        var dock = document.querySelector('.dock');
        if (dock && dock.classList.contains('dock-open')) {
          // Fermer
          dock.classList.remove('dock-open');
          document.body.classList.remove('dock-is-open');
          var panels = dock.querySelectorAll('.dock-panel');
          panels.forEach(function(p) { p.classList.remove('panel-active'); });
          // TOGGLER : retour horizontal
          menuToggle.classList.remove('rotated');
          menuToggle.classList.remove('active');
          updateNavButtons(null);
        } else if (dock) {
          // Ouvrir
          var locPanel = dock.querySelector('[data-panel="localisation"]');
          if (locPanel) {
            locPanel.classList.add('panel-active');
          }
          dock.classList.add('dock-open');
          document.body.classList.add('dock-is-open');
          // TOGGLER : rotation 90°
          menuToggle.classList.add('rotated');
          menuToggle.classList.remove('active');
          updateNavButtons('localisation');
        }
      }
    });

    console.log('[cartOLD][Dock] Navigation initialisée ✓');
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initDockNavigation);
  } else {
    initDockNavigation();
  }

  document.addEventListener('shiny:connected', function() {
    setTimeout(initDockNavigation, 100);
  });

})();

// ══════════════════════════════════════════════════════════════════════════════
// MODULE AIDE OVERLAY
// ══════════════════════════════════════════════════════════════════════════════
(function() {
  'use strict';

  const CONFIG = {
    overlayClass: 'aide-carte-overlay',
    visibleClass: 'aide-visible',
    hiddenClass: 'hidden',
    animationDuration: 300,
    debug: false
  };

  function log(...args) {
    if (CONFIG.debug && console && console.log) {
      console.log('[cartOLD][Aide]', ...args);
    }
  }

  function findElement(id) {
    if (!id) return null;

    let el = document.getElementById(id);
    if (el) return el;

    const parts = id.split('-');
    if (parts.length > 1) {
      const lastPart = parts[parts.length - 1];
      const selectors = [
        `[id$="-${lastPart}"]`,
        `[id*="${lastPart}"]`,
        `.${CONFIG.overlayClass}`
      ];

      for (const selector of selectors) {
        el = document.querySelector(selector);
        if (el) return el;
      }
    }

    return document.querySelector(`.${CONFIG.overlayClass}`);
  }

  function showAideOverlay(overlay) {
    if (!overlay) return;

    overlay.classList.remove(CONFIG.hiddenClass);
    void overlay.offsetWidth;
    overlay.classList.add(CONFIG.visibleClass);

    const carteZone = overlay.closest('.conteneur-carte');
    if (carteZone) carteZone.style.overflow = 'hidden';
  }

  function hideAideOverlay(overlay) {
    if (!overlay) return;

    overlay.classList.remove(CONFIG.visibleClass);

    setTimeout(() => {
      overlay.classList.add(CONFIG.hiddenClass);
      const carteZone = overlay.closest('.conteneur-carte');
      if (carteZone) carteZone.style.overflow = '';
    }, CONFIG.animationDuration);
  }

  function toggleAideOverlay(overlay) {
    if (!overlay) return;

    const isVisible = overlay.classList.contains(CONFIG.visibleClass);
    if (isVisible) {
      hideAideOverlay(overlay);
    } else {
      showAideOverlay(overlay);
    }
  }

  function processToggleCommand(overlay, message) {
    if (message.show === false) {
      hideAideOverlay(overlay);
      return;
    }

    if (message.show === true) {
      showAideOverlay(overlay);
      return;
    }

    toggleAideOverlay(overlay);
  }

  function handleToggleAideCarte(message) {
    const overlayId = message.id || message;
    const overlay = findElement(overlayId);

    if (!overlay) {
      const fallbackOverlay = document.querySelector(`.${CONFIG.overlayClass}`);
      if (fallbackOverlay) {
        processToggleCommand(fallbackOverlay, message);
      }
      return;
    }

    processToggleCommand(overlay, message);
  }

  function initAideModule() {
    if (!window.Shiny) {
      setTimeout(initAideModule, 200);
      return;
    }

    Shiny.addCustomMessageHandler('toggleAideCarte', handleToggleAideCarte);

    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' || e.keyCode === 27) {
        const overlay = document.querySelector(`.${CONFIG.overlayClass}`);
        if (overlay && overlay.classList.contains(CONFIG.visibleClass)) {
          hideAideOverlay(overlay);
        }
      }
    });

    document.addEventListener('click', function(e) {
      if (e.target && e.target.classList.contains('aide-backdrop')) {
        const overlay = e.target.closest(`.${CONFIG.overlayClass}`);
        if (overlay) {
          hideAideOverlay(overlay);
        }
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAideModule);
  } else {
    initAideModule();
  }

  document.addEventListener('shiny:connected', function() {
    setTimeout(initAideModule, 100);
  });

})();

// ══════════════════════════════════════════════════════════════════════════════
// FIN DU FICHIER
// ══════════════════════════════════════════════════════════════════════════════
